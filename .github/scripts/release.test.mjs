import { afterEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parseVersion, compareVersions, updateVersions, sourceVersion, shouldMakeLatest } from './release_version.mjs';
import { assetNames, digest, packAssets, verifyAssets, verifyRemoteAssets } from './release_assets.mjs';
import { prepareRelease, pushRelease, publishRelease, assertRemoteTag } from './release.mjs';

const roots = [];
const script = fileURLToPath(new URL('./release.mjs', import.meta.url));
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
function git(directory, ...args) {
  return execFileSync('git', args, { cwd: directory, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-release-test-'));
  roots.push(root);
  const directory = path.join(root, 'work'), remote = path.join(root, 'remote.git');
  fs.mkdirSync(directory);
  git(root, 'init', '--bare', '--initial-branch=main', remote);
  git(directory, 'init', '--initial-branch=main');
  git(directory, 'config', 'user.name', 'Release test');
  git(directory, 'config', 'user.email', 'release@example.invalid');
  fs.mkdirSync(path.join(directory, 'ls'));
  fs.writeFileSync(path.join(directory, 'version.zsh'), '# Version\nz.version() {\n  z.io "v0.7.0"\n}\n# Keep this helper\n');
  fs.writeFileSync(path.join(directory, 'ls/package.json'), JSON.stringify({
    name: 'z-ls', publisher: 'milkeclair', version: '2.3.0', dependencies: { example: '1.0.0' },
  }, null, 2) + '\n');
  fs.writeFileSync(path.join(directory, 'ls/package-lock.json'), JSON.stringify({
    name: 'z-ls', version: '2.3.0', packages: { '': { version: '2.3.0' }, 'node_modules/example': { version: '1.0.0', integrity: 'unchanged' } },
  }, null, 2) + '\n');
  for (const name of ['lib/a.zsh', 'mod/example/mod.zsh', 'test/a_test.zsh']) {
    fs.mkdirSync(path.dirname(path.join(directory, name)), { recursive: true });
    fs.writeFileSync(path.join(directory, name), ': \n');
  }
  git(directory, 'add', '.');
  git(directory, 'commit', '-m', 'Initial source');
  git(directory, 'remote', 'add', 'origin', remote);
  git(directory, 'push', '-u', 'origin', 'main');
  return { root, directory, remote, source: git(directory, 'rev-parse', 'HEAD') };
}
function makeVsix(directory, version = '2.4.0') {
  fs.mkdirSync(directory, { recursive: true });
  const filename = path.join(directory, 'z-ls-2.4.0.vsix');
  execFileSync('python3', ['-c', [
    'import zipfile,json,sys',
    'with zipfile.ZipFile(sys.argv[1],"w") as archive:',
    ' archive.writestr("extension/package.json",json.dumps({"name":"z-ls","publisher":"milkeclair","version":sys.argv[2]}))',
    ' archive.writestr("extension/client/dist/extension.js","")',
    ' archive.writestr("extension/server/dist/server.js","")',
  ].join('\n'), filename, version]);
}
function releaseFixture() {
  const item = fixture();
  prepareRelease(item.directory, '2.4.0', 'new', item.source);
  const assets = path.join(item.root, 'assets');
  makeVsix(assets);
  packAssets(item.directory, assets, '2.4.0');
  return { ...item, assets };
}
function remoteData(assets) {
  return { tag_name: 'v2.4.0', draft: true, prerelease: false, immutable: false,
    assets: assetNames('2.4.0').map(name => ({ name, state: 'uploaded', digest: 'sha256:' + digest(path.join(assets, name)) })) };
}
function plan(item, response, status = '200', version = '2.4.0') {
  const bin = path.join(item.root, 'bin');
  fs.mkdirSync(bin, { recursive: true });
  fs.writeFileSync(path.join(bin, 'gh'), '#!' + process.execPath + '\n' +
    'if(process.env.RELEASE_TEST_STATUS==="200")process.stdout.write(process.env.RELEASE_TEST_RESPONSE);' +
    'else {process.stderr.write("gh: HTTP "+process.env.RELEASE_TEST_STATUS);process.exit(1);}\n', { mode: 0o755 });
  return spawnSync(process.execPath, [script, 'plan', version, 'milkeclair/z', git(item.directory, 'rev-parse', 'HEAD')], {
    cwd: item.directory, encoding: 'utf8', env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH,
      RELEASE_TEST_STATUS: status, RELEASE_TEST_RESPONSE: JSON.stringify(response) },
  });
}

describe('unified release versions', () => {
  test('accepts canonical stable versions and orders numeric components', () => {
    assert.deepEqual(parseVersion('2.4.0'), [2, 4, 0]);
    assert.ok(compareVersions('2.10.0', '2.9.0') > 0);
    assert.equal(compareVersions('2.4.0', '2.4.0'), 0);
  });
  test('keeps Latest on the newer release when an older draft is resumed', () => {
    assert.equal(shouldMakeLatest('2.4.0', null), true);
    assert.equal(shouldMakeLatest('2.4.0', 'v0.8.2'), true);
    assert.equal(shouldMakeLatest('2.4.0', '0.8.0'), true);
    assert.equal(shouldMakeLatest('2.4.0', 'v2.5.0'), false);
    assert.equal(shouldMakeLatest('2.4.0', 'v2.4.0'), false);
  });
  test('rejects prefixes, whitespace, prereleases, unsafe integers and shell syntax', () => {
    for (const version of ['', 'v2.4.0', '02.4.0', '2.4', '2.4.0\n', ' 2.4.0', '2.4.0-alpha', '2.4.0+build', '9007199254740992.0.0', '2.4.0; touch /tmp/invalid']) {
      assert.throws(() => parseVersion(version), Error, version);
    }
  });
  test('updates source, package and lock versions without changing helpers or dependencies', () => {
    const item = fixture();
    updateVersions(item.directory, '2.4.0');
    const source = fs.readFileSync(path.join(item.directory, 'version.zsh'), 'utf8');
    assert.equal(sourceVersion(source), '2.4.0');
    assert.ok(source.endsWith('# Keep this helper\n'));
    const lock = JSON.parse(fs.readFileSync(path.join(item.directory, 'ls/package-lock.json')));
    assert.equal(lock.version, '2.4.0');
    assert.equal(lock.packages[''].version, '2.4.0');
    assert.equal(lock.packages['node_modules/example'].integrity, 'unchanged');
    assert.deepEqual(git(item.directory, 'diff', '--name-only').split('\n'), ['ls/package-lock.json', 'ls/package.json', 'version.zsh']);
  });
  test('rejects reused or lower versions before modifying any source', () => {
    const item = fixture();
    assert.throws(() => updateVersions(item.directory, '2.3.0'), /newer/);
    assert.throws(() => updateVersions(item.directory, '0.9.0'), /newer/);
    assert.equal(git(item.directory, 'status', '--porcelain'), '');
  });
  test('rejects inconsistent npm metadata before modifying source', () => {
    const item = fixture();
    const filename = path.join(item.directory, 'ls/package-lock.json');
    const lock = JSON.parse(fs.readFileSync(filename));lock.packages[''].version = '2.2.0';
    fs.writeFileSync(filename, JSON.stringify(lock));
    assert.throws(() => updateVersions(item.directory, '2.4.0'), /mismatch/);
    assert.equal(sourceVersion(fs.readFileSync(path.join(item.directory, 'version.zsh'), 'utf8')), '0.7.0');
  });
});

describe('release state and atomic pushes', () => {
  test('treats only a real 404 as an absent release', () => {
    const item = fixture();
    const absent = plan(item, {}, '404');
    assert.equal(absent.status, 0, absent.stderr);
    assert.equal(absent.stdout.trim(), 'new');
    for (const status of ['403', '500']) assert.notEqual(plan(item, {}, status).status, 0);
  });
  test('reuses published immutable releases and rejects mutable ones', () => {
    const item = fixture();
    const published = plan(item, { draft: false, immutable: true });
    assert.equal(published.status, 0, published.stderr);
    assert.equal(published.stdout.trim(), 'published');
    assert.notEqual(plan(item, { draft: false, immutable: false }).status, 0);
  });
  test('creates a local version commit and tag before any remote write', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    assert.equal(git(item.directory, 'rev-parse', 'HEAD^'), item.source);
    assert.equal(git(item.directory, 'rev-parse', 'v2.4.0^{commit}'), git(item.directory, 'rev-parse', 'HEAD'));
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'tag'), '');
  });
  test('pushes main and the annotated tag together and recovers an unpublished tag', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    pushRelease(item.directory, '2.4.0', item.source);
    const commit = git(item.directory, 'rev-parse', 'HEAD');
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), commit);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'v2.4.0^{commit}'), commit);
    const resumed = plan(item, {}, '404');
    assert.equal(resumed.status, 0, resumed.stderr);
    assert.equal(resumed.stdout.trim(), 'resume');
    prepareRelease(item.directory, '2.4.0', 'resume', commit);
    assert.equal(git(item.directory, 'rev-parse', 'HEAD'), commit);
  });
  test('refuses to resume a tag other than the commit validated by CI', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    assert.throws(() => prepareRelease(item.directory, '2.4.0', 'resume', item.source), /tag changed after validation/);
  });
  test('detects a remote tag move before publishing any assets', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    pushRelease(item.directory, '2.4.0', item.source);
    assertRemoteTag(item.directory, '2.4.0');
    git(item.root, '--git-dir=' + item.remote, 'update-ref', 'refs/tags/v2.4.0', item.source);
    assert.throws(() => assertRemoteTag(item.directory, '2.4.0'), /Remote release tag changed/);
  });
  test('rejects a stale dispatch before creating a new release', () => {
    const item = fixture();
    fs.writeFileSync(path.join(item.directory, 'later'), 'new main');
    git(item.directory, 'add', '.');git(item.directory, 'commit', '-m', 'Advance main');git(item.directory, 'push', 'origin', 'main');
    git(item.directory, 'checkout', '--detach', item.source);
    const result = plan(item, {}, '404');
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /main advanced/);
  });
  test('rejects a concurrent main update without pushing the release tag', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    const other = path.join(item.root, 'other');
    git(item.root, 'clone', item.remote, other);
    git(other, 'config', 'user.name', 'Other');git(other, 'config', 'user.email', 'other@example.invalid');
    fs.writeFileSync(path.join(other, 'later'), 'new main');
    git(other, 'add', '.');git(other, 'commit', '-m', 'Advance main');git(other, 'push', 'origin', 'main');
    assert.throws(() => pushRelease(item.directory, '2.4.0', item.source), /main advanced/);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'tag'), '');
  });
  test('an existing conflicting remote tag prevents an atomic main update', () => {
    const item = fixture();
    git(item.root, '--git-dir=' + item.remote, 'tag', 'v2.4.0', item.source);
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    assert.throws(() => pushRelease(item.directory, '2.4.0', item.source));
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'v2.4.0'), item.source);
  });
});

describe('complete immutable release assets', () => {
  test('archives lib, mod, tests and versioned LSP source alongside the matching VSIX', () => {
    const item = releaseFixture();
    verifyAssets(item.assets, '2.4.0');
    const names = execFileSync('tar', ['-tzf', path.join(item.assets, 'z-2.4.0.tar.gz')], { encoding: 'utf8' });
    for (const name of ['lib/a.zsh', 'mod/example/mod.zsh', 'test/a_test.zsh', 'ls/package.json']) assert.ok(names.includes('z-2.4.0/' + name));
    const first = digest(path.join(item.assets, 'z-2.4.0.tar.gz'));
    packAssets(item.directory, item.assets, '2.4.0');
    assert.equal(digest(path.join(item.assets, 'z-2.4.0.tar.gz')), first);
  });
  test('rejects tracked source changes made after the version commit', () => {
    const item = releaseFixture();
    fs.appendFileSync(path.join(item.directory, 'lib/a.zsh'), 'print changed\n');
    assert.throws(() => packAssets(item.directory, item.assets, '2.4.0'), /source changed during/);
  });
  test('rejects a version mismatch even when checksums match', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    const assets = path.join(item.root, 'assets');makeVsix(assets, '2.3.0');
    assert.throws(() => packAssets(item.directory, assets, '2.4.0'), /VSIX version/);
  });
  test('rejects corrupted bytes and altered checksum paths before any publication', () => {
    const item = releaseFixture();
    fs.appendFileSync(path.join(item.assets, 'z-ls-2.4.0.vsix'), 'corrupt');
    assert.throws(() => publishRelease(item.directory, '2.4.0', 'milkeclair/z', item.assets, 'new', item.source), /checksums/);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
    fs.writeFileSync(path.join(item.assets, 'SHA256SUMS'), '0  ../outside\n');
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /checksums/);
  });
  test('requires the exact uploaded asset set and digest before publishing', () => {
    const item = releaseFixture(), release = remoteData(item.assets);
    verifyRemoteAssets(release, item.assets, '2.4.0');
    assert.throws(() => verifyRemoteAssets({ ...release, assets: release.assets.slice(1) }, item.assets, '2.4.0'), /exactly/);
    assert.throws(() => verifyRemoteAssets({ ...release, assets: [...release.assets, release.assets[0]] }, item.assets, '2.4.0'), /exactly/);
    const changed = { ...release, assets: release.assets.map(asset => ({ ...asset, digest: 'sha256:bad' })) };
    assert.throws(() => verifyRemoteAssets(changed, item.assets, '2.4.0'), /mismatched/);
  });
  test('requires published immutable state for reuse and rejects overwriting published assets', () => {
    const item = releaseFixture(), release = remoteData(item.assets);
    const published = { ...release, draft: false, immutable: true };
    verifyRemoteAssets(published, item.assets, '2.4.0', true);
    assert.throws(() => verifyRemoteAssets({ ...published, immutable: false }, item.assets, '2.4.0', true), /immutable/);
    assert.throws(() => verifyRemoteAssets(published, item.assets, '2.4.0'), /never overwritten/);
  });
});

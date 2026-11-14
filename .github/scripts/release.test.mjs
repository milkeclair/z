import { afterEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parseVersion, compareVersions, updateVersions, sourceVersion, shouldMakeLatest } from './release_version.mjs';
import { assetNames, digest, packAssets, verifyAssets, verifyRemoteAssets, verifySourceArchive } from './release_assets.mjs';
import { prepareRelease, pushRelease, publishRelease, assertRemoteTag, assertMarketplaceEnvironment, releaseNotes } from './release.mjs';

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
function makeVsix(directory, version = '2.4.0', xmlId = 'z-ls', properties = '') {
  fs.mkdirSync(directory, { recursive: true });
  const filename = path.join(directory, 'z-ls-2.4.0.vsix');
  execFileSync('python3', ['-c', [
    'import zipfile,json,sys',
    'with zipfile.ZipFile(sys.argv[1],"w") as archive:',
    ' archive.writestr("extension/package.json",json.dumps({"name":"z-ls","publisher":"milkeclair","version":sys.argv[2]}))',
    ' archive.writestr("extension.vsixmanifest",\'<PackageManifest xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011"><Metadata><Identity Id="\'+sys.argv[3]+\'" Publisher="milkeclair" Version="\'+sys.argv[2]+\'"/>\'+sys.argv[4]+\'</Metadata></PackageManifest>\')',
    ' archive.writestr("extension/client/dist/extension.js","")',
    ' archive.writestr("extension/server/dist/server.js","")',
  ].join('\n'), filename, version, xmlId, properties]);
}
function releaseFixture() {
  const item = fixture();
  prepareRelease(item.directory, '2.4.0', 'new', item.source);
  const assets = path.join(item.root, 'assets');
  makeVsix(assets);
  packAssets(item.directory, assets, '2.4.0');
  const notesFile = path.join(item.root, 'release-notes.md');
  fs.writeFileSync(notesFile, '## Changes\n\n- Test release\n');
  return { ...item, assets, notesFile };
}
function remoteData(assets) {
  return { tag_name: 'v2.4.0', draft: true, prerelease: false, immutable: false,
    assets: assetNames('2.4.0').map(name => ({ name, state: 'uploaded', digest: 'sha256:' + digest(path.join(assets, name)) })) };
}
function plan(item, response, status = '200', version = '2.4.0') {
  const bin = path.join(item.root, 'bin');
  fs.mkdirSync(bin, { recursive: true });
  fs.writeFileSync(path.join(bin, 'gh'), '#!' + process.execPath + '\n' +
    'if(process.argv[2]!=="release"||process.argv[3]!=="view")throw new Error("Use draft-aware release lookup");' +
    'if(process.env.RELEASE_TEST_STATUS==="200"){const v=JSON.parse(process.env.RELEASE_TEST_RESPONSE);' +
    'process.stdout.write(JSON.stringify({tagName:v.tag_name,isDraft:v.draft,isImmutable:v.immutable,isPrerelease:v.prerelease,assets:v.assets}));}' +
    'else {process.stderr.write(process.env.RELEASE_TEST_STATUS==="404"?"release not found":"gh: HTTP "+process.env.RELEASE_TEST_STATUS);process.exit(1);}\n', { mode: 0o755 });
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
  test('treats only a missing release as absent and preserves other service errors', () => {
    const item = fixture();
    const absent = plan(item, {}, '404');
    assert.equal(absent.status, 0, absent.stderr);
    assert.equal(absent.stdout.trim(), 'new');
    for (const status of ['403', '500']) assert.notEqual(plan(item, {}, status).status, 0);
  });
  test('recognizes a draft that the published-by-tag REST endpoint would not return', () => {
    const item = fixture();
    const result = plan(item, { tag_name: 'v2.4.0', draft: true, immutable: false });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Draft release has no source tag/);
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
  test('rejects unrelated code hidden inside an amended version commit', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    git(item.directory, 'reset', '--soft', item.source);
    fs.appendFileSync(path.join(item.directory, 'lib/a.zsh'), 'print unexpected\n');
    git(item.directory, 'add', '.');
    git(item.directory, 'commit', '-m', 'release: v2.4.0');
    git(item.directory, 'tag', '--force', '--annotate', 'v2.4.0', '--message', 'Release v2.4.0');
    assert.throws(() => pushRelease(item.directory, '2.4.0', item.source), /version commit|metadata|version-bearing/);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
  });
  test('rejects non-version edits inside the managed version file', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    git(item.directory, 'reset', '--soft', item.source);
    fs.appendFileSync(path.join(item.directory, 'version.zsh'), '# unapproved extra content\n');
    git(item.directory, 'add', '.');
    git(item.directory, 'commit', '-m', 'release: v2.4.0');
    git(item.directory, 'tag', '--force', '--annotate', 'v2.4.0', '--message', 'Release v2.4.0');
    assert.throws(() => pushRelease(item.directory, '2.4.0', item.source), /version commit|metadata|version-bearing/);
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

describe('author-written release notes', () => {
  test('requires non-empty notes and preserves Markdown and whitespace', () => {
    for (const notes of [undefined, null, '', ' \t\r\n']) {
      assert.throws(() => releaseNotes(notes), /Release notes are required/);
    }
    const notes = '  ## 変更\r\n\r\n- Fix "quotes" and $HOME\r\n\r\n';
    assert.equal(releaseNotes(notes), notes);
  });

  test('writes multiline input literally through the workflow shell boundary', () => {
    const item = fixture(), filename = path.join(item.root, 'notes.md');
    const marker = path.join(item.root, 'should-not-exist');
    const notes = '## 変更\r\n\r\n- "quoted" \'text\' $HOME $(touch ' + marker + ') ' +
      String.fromCharCode(96) + 'touch ' + marker + String.fromCharCode(96) +
      '\nEOF\n::error::ordinary Markdown\n--generate-notes\n';
    const result = spawnSync('bash', ['-euo', 'pipefail', '-c',
      '"$NODE" "$RELEASE_SCRIPT" notes "$RELEASE_NOTES" "$NOTES_FILE"'], {
      encoding: 'utf8', env: { ...process.env, NODE: process.execPath, RELEASE_SCRIPT: script,
        RELEASE_NOTES: notes, NOTES_FILE: filename },
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(filename, 'utf8'), notes);
    assert.equal(result.stdout, '');
    assert.equal(fs.existsSync(marker), false);
  });

  test('rejects missing or blank CLI input without creating a notes file', () => {
    const item = fixture(), filename = path.join(item.root, 'notes.md');
    for (const args of [[], ['', filename], [' \n\t', filename]]) {
      const result = spawnSync(process.execPath, [script, 'notes', ...args], { encoding: 'utf8' });
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, /Release notes are required/);
      assert.equal(fs.existsSync(filename), false);
    }
  });

  test('rejects blank notes before pushing main or a release tag', () => {
    const item = releaseFixture();
    fs.writeFileSync(item.notesFile, ' \n');
    assert.throws(() => publishRelease(item.directory, '2.4.0', 'milkeclair/z',
      item.assets, 'new', item.source, item.notesFile), /Release notes are required/);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'tag'), '');
  });

  for (const existingDraft of [false, true]) {
    test(existingDraft ? 'replaces an existing draft body with this dispatch input' :
      'creates and publishes a draft using only the supplied notes', () => {
      const item = releaseFixture(), bin = path.join(item.root, 'bin');
      fs.mkdirSync(bin);
      const notes = '## 変更\n\n- "quotes" $HOME $(false)\n\n';
      fs.writeFileSync(item.notesFile, notes);
      if (existingDraft) pushRelease(item.directory, '2.4.0', item.source);
      const callsFile = path.join(item.root, 'gh-calls.jsonl'), stateFile = path.join(item.root, 'release.json');
      if (existingDraft) fs.writeFileSync(stateFile, JSON.stringify({ ...remoteData(item.assets), body: 'Old draft notes' }));
      fs.writeFileSync(path.join(bin, 'gh'), '#!' + process.execPath + '\n' + [
        'const fs = require("node:fs");',
        'const args = process.argv.slice(2), stateFile = process.env.RELEASE_TEST_STATE;',
        'let state = fs.existsSync(stateFile) ? JSON.parse(fs.readFileSync(stateFile)) : null;',
        'const notesIndex = args.indexOf("--notes-file");',
        'const body = notesIndex < 0 ? null : fs.readFileSync(args[notesIndex + 1], "utf8");',
        'fs.appendFileSync(process.env.RELEASE_TEST_CALLS, JSON.stringify({ args, body }) + "\\n");',
        'if (args[0] === "release" && args[1] === "view") {',
        '  if (!state) { process.stderr.write("release not found"); process.exit(1); }',
        '  process.stdout.write(JSON.stringify({tagName: state.tag_name, isDraft: state.draft, isImmutable: state.immutable, isPrerelease: state.prerelease, assets: state.assets}));',
        '} else if (args[0] === "release" && args[1] === "create") {',
        '  if (body === null || args.includes("--generate-notes")) throw new Error("Expected authored notes file");',
        '  state = { ...JSON.parse(process.env.RELEASE_TEST_DATA), body };',
        '} else if (args[0] === "release" && args[1] === "upload") {',
        '  if (!state || !state.draft) throw new Error("Expected mutable draft");',
        '} else if (args[0] === "api" && args[1].endsWith("/releases/latest")) {',
        '  process.stderr.write("gh: HTTP 404"); process.exit(1);',
        '} else if (args[0] === "release" && args[1] === "edit") {',
        '  if (body === null || !args.includes("--draft=false")) throw new Error("Expected notes at publication");',
        '  state = { ...state, body, draft: false, immutable: true };',
        '} else { throw new Error("Unexpected gh command: " + JSON.stringify(args)); }',
        'if (state) fs.writeFileSync(stateFile, JSON.stringify(state));',
      ].join('\n') + '\n', { mode: 0o755 });
      const result = spawnSync(process.execPath, [script, 'publish', '2.4.0', 'milkeclair/z',
        item.source, item.assets, existingDraft ? 'resume' : 'new', item.notesFile], {
        cwd: item.directory, encoding: 'utf8', env: { ...process.env,
          PATH: bin + path.delimiter + process.env.PATH, RELEASE_TEST_STATE: stateFile,
          RELEASE_TEST_CALLS: callsFile, RELEASE_TEST_DATA: JSON.stringify(remoteData(item.assets)) },
      });
      assert.equal(result.status, 0, result.stderr);
      const calls = fs.readFileSync(callsFile, 'utf8').trim().split('\n').map(line => JSON.parse(line));
      const writes = calls.filter(call => call.args[0] === 'release' && ['create', 'edit'].includes(call.args[1]));
      assert.deepEqual(writes.map(call => call.args[1]), existingDraft ? ['edit'] : ['create', 'edit']);
      for (const call of writes) {
        assert.equal(call.body, notes);
        assert.ok(!call.args.includes('--generate-notes'));
      }
      const published = JSON.parse(fs.readFileSync(stateFile));
      assert.equal(published.body, notes);
      assert.equal(published.draft, false);
      assert.equal(published.immutable, true);
    });
  }
});

describe('complete immutable release assets', () => {
  test('archives lib, mod, tests and versioned LSP source alongside the matching VSIX', () => {
    const item = releaseFixture();
    verifyAssets(item.assets, '2.4.0');
    const names = execFileSync('tar', ['-tzf', path.join(item.assets, 'z-2.4.0.tar.gz')], { encoding: 'utf8' });
    for (const name of ['lib/a.zsh', 'mod/example/mod.zsh', 'test/a_test.zsh', 'ls/package.json']) assert.ok(names.includes('z-2.4.0/' + name));
    const first = digest(path.join(item.assets, 'z-2.4.0.tar.gz'));
    const header = execFileSync('gzip', ['-dc', path.join(item.assets, 'z-2.4.0.tar.gz')]);
    assert.equal(parseInt(header.subarray(136, 148).toString().replaceAll('\0', ''), 8),
      Number(git(item.directory, 'show', '-s', '--format=%ct', 'HEAD^')));
    verifySourceArchive(item.directory, item.assets, '2.4.0', 'v2.4.0');
    packAssets(item.directory, item.assets, '2.4.0');
    assert.equal(digest(path.join(item.assets, 'z-2.4.0.tar.gz')), first);
  });
  test('source archives agree across independently recreated version commits', () => {
    const item = releaseFixture();
    const original = digest(path.join(item.assets, 'z-2.4.0.tar.gz'));
    git(item.directory, 'commit', '--amend', '--no-edit', '--date=2000-01-01T00:00:00Z');
    packAssets(item.directory, item.assets, '2.4.0');
    assert.equal(digest(path.join(item.assets, 'z-2.4.0.tar.gz')), original);
  });
  test('rejects a forged source tree even when its checksums and versions are self-consistent', () => {
    const item = releaseFixture();
    const validated = git(item.directory, 'rev-parse', 'HEAD');
    fs.appendFileSync(path.join(item.directory, 'lib/a.zsh'), 'print untrusted\n');
    git(item.directory, 'add', '.');git(item.directory, 'commit', '-m', 'Untrusted builder state');
    packAssets(item.directory, item.assets, '2.4.0');
    verifyAssets(item.assets, '2.4.0');
    git(item.directory, 'checkout', '--detach', validated);
    assert.throws(() => verifySourceArchive(item.directory, item.assets, '2.4.0'), /validated Git tree/);
    assert.throws(() => publishRelease(item.directory, '2.4.0', 'local-test-only', item.assets, 'new', item.source, item.notesFile), /validated Git tree/);
    assert.equal(git(item.root, '--git-dir=' + item.remote, 'rev-parse', 'main'), item.source);
  });
  test('rejects a VSIX XML identity that differs from its valid JSON identity', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    const assets = path.join(item.root, 'assets');makeVsix(assets, '2.4.0', 'another-extension');
    assert.throws(() => packAssets(item.directory, assets, '2.4.0'), /VSIX XML identity/);
  });
  test('rejects a pre-release flag hidden in an otherwise matching VSIX', () => {
    const item = fixture();
    prepareRelease(item.directory, '2.4.0', 'new', item.source);
    const assets = path.join(item.root, 'assets');
    makeVsix(assets, '2.4.0', 'z-ls',
      '<Properties><Property Id="Microsoft.VisualStudio.Code.PreRelease" Value="true"/></Properties>');
    assert.throws(() => packAssets(item.directory, assets, '2.4.0'), /stable VSIX/);
  });
  test('rejects XML namespace differentials before a downstream parser can choose another identity', () => {
    const item = releaseFixture(), filename = path.join(item.assets, 'z-ls-2.4.0.vsix');
    execFileSync('python3', ['-c', [
      'import io,zipfile,sys',
      'target=io.BytesIO()',
      'with zipfile.ZipFile(sys.argv[1]) as old, zipfile.ZipFile(target,"w") as new:',
      ' for entry in old.infolist():',
      '  data=old.read(entry.filename)',
      '  if entry.filename=="extension.vsixmanifest": data=data.replace(b"<Metadata>",b\'<Metadata xmlns=""><Identity Id="other" Publisher="milkeclair" Version="2.4.0"/></Metadata><Metadata>\',1)',
      '  new.writestr(entry,data)',
      'open(sys.argv[1],"wb").write(target.getvalue())',
    ].join('\n'), filename]);
    fs.writeFileSync(path.join(item.assets, 'SHA256SUMS'),
      assetNames('2.4.0').slice(0, 2).map(file => digest(path.join(item.assets, file)) + '  ' + file + '\n').join(''));
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /XML element namespace|unambiguous/);
  });
  test('rejects downloaded symlinks and unexpected additional files', () => {
    const item = releaseFixture();
    fs.writeFileSync(path.join(item.assets, 'extra'), 'unexpected');
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /Unexpected release files/);
    fs.unlinkSync(path.join(item.assets, 'extra'));
    const target = path.join(item.root, 'outside-source');
    fs.renameSync(path.join(item.assets, 'z-2.4.0.tar.gz'), target);
    fs.symlinkSync(target, path.join(item.assets, 'z-2.4.0.tar.gz'));
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /bounded regular/);
  });
  test('rejects duplicate ZIP metadata and traversal paths despite matching checksums', () => {
    for (const name of ['extension/package.json', '../outside', 'extension/PACKAGE.JSON', 'extension/package.json/']) {
      const item = releaseFixture();
      execFileSync('python3', ['-c', 'import zipfile,sys\nwith zipfile.ZipFile(sys.argv[1],"a") as z: z.writestr(sys.argv[2],"{}")',
        path.join(item.assets, 'z-ls-2.4.0.vsix'), name]);
      fs.writeFileSync(path.join(item.assets, 'SHA256SUMS'),
        assetNames('2.4.0').slice(0, 2).map(file => digest(path.join(item.assets, file)) + '  ' + file + '\n').join(''));
      assert.throws(() => verifyAssets(item.assets, '2.4.0'), /Duplicate|Unsafe VSIX/);
    }
  });
  test('checks file size before reading an oversized sparse VSIX', () => {
    const item = releaseFixture();
    fs.truncateSync(path.join(item.assets, 'z-ls-2.4.0.vsix'), 128 * 1024 * 1024 + 1);
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /bounded regular/);
  });
  test('rejects oversized XML before parsing it', () => {
    const item = releaseFixture();
    const filename = path.join(item.assets, 'z-ls-2.4.0.vsix');
    execFileSync('python3', ['-c', [
      'import io,zipfile,sys',
      'target=io.BytesIO()',
      'with zipfile.ZipFile(sys.argv[1]) as old, zipfile.ZipFile(target,"w") as new:',
      ' for entry in old.infolist(): new.writestr(entry, b"x"*(1024*1024+1) if entry.filename=="extension.vsixmanifest" else old.read(entry.filename))',
      'open(sys.argv[1],"wb").write(target.getvalue())',
    ].join('\n'), filename]);
    fs.writeFileSync(path.join(item.assets, 'SHA256SUMS'),
      assetNames('2.4.0').slice(0, 2).map(file => digest(path.join(item.assets, file)) + '  ' + file + '\n').join(''));
    assert.throws(() => verifyAssets(item.assets, '2.4.0'), /metadata exceeds/);
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
    assert.throws(() => packAssets(item.directory, assets, '2.4.0'), /VSIX.*identity/);
  });
  test('rejects corrupted bytes and altered checksum paths before any publication', () => {
    const item = releaseFixture();
    fs.appendFileSync(path.join(item.assets, 'z-ls-2.4.0.vsix'), 'corrupt');
    assert.throws(() => publishRelease(item.directory, '2.4.0', 'local-test-only', item.assets, 'new', item.source, item.notesFile), /checksums/);
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

describe('Marketplace OIDC environment boundary', () => {
  const locked = { deployment_branch_policy: { protected_branches: false, custom_branch_policies: true } };
  test('accepts only one explicit branch main policy', () => {
    assertMarketplaceEnvironment(locked, [{ name: 'main', type: 'branch' }]);
  });
  test('rejects absent, unrestricted or all-protected-branches environments', () => {
    for (const environment of [null, {}, { deployment_branch_policy: null },
      { deployment_branch_policy: { protected_branches: true, custom_branch_policies: false } }]) {
      assert.throws(() => assertMarketplaceEnvironment(environment, [{ name: 'main', type: 'branch' }]), /only branch main/);
    }
  });
  test('rejects a main tag, wildcard, missing type, empty list or additional allowed branch', () => {
    for (const policies of [[], [{ name: 'main', type: 'tag' }], [{ name: '*', type: 'branch' }],
      [{ name: 'main' }], [{ name: 'main', type: 'branch' }, { name: 'feature', type: 'branch' }]]) {
      assert.throws(() => assertMarketplaceEnvironment(locked, policies), /only branch main/);
    }
  });
});

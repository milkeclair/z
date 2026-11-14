import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { gzipSync } from 'node:zlib';
import { assertVersions, parseVersion } from './release_version.mjs';

/** Return the complete asset set for one unified version. */
export function assetNames(version) {
  parseVersion(version);
  return ['z-' + version + '.tar.gz', 'z-ls-' + version + '.vsix', 'SHA256SUMS'];
}

/** Calculate a release file's SHA256 digest. */
export function digest(filename) {
  return createHash('sha256').update(fs.readFileSync(filename)).digest('hex');
}

/** Check packaged metadata and all checksum entries without extracting executable files. */
export function verifyAssets(directory, version) {
  const [archive, vsix, sums] = assetNames(version);
  const expected = [archive, vsix].map(name => digest(path.join(directory, name)) + '  ' + name + '\n').join('');
  if (fs.readFileSync(path.join(directory, sums), 'utf8') !== expected) throw new Error('Release checksums do not match.');
  const readTar = name => execFileSync('tar', ['-xzOf', path.join(directory, archive), 'z-' + version + '/' + name], { encoding: 'utf8' });
  const manifest = JSON.parse(readTar('ls/package.json'));
  assertVersions(readTar('version.zsh'), manifest, JSON.parse(readTar('ls/package-lock.json')), version);
  const packageManifest = JSON.parse(execFileSync('unzip', ['-p', path.join(directory, vsix), 'extension/package.json'], { encoding: 'utf8' }));
  if (packageManifest.version !== version || packageManifest.name !== 'z-ls' ||
      packageManifest.publisher !== 'milkeclair' || manifest.name !== packageManifest.name ||
      manifest.publisher !== packageManifest.publisher) throw new Error('Unexpected VSIX version or extension identity.');
  const entries = execFileSync('unzip', ['-Z1', path.join(directory, vsix)], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }).split('\n');
  for (const name of ['client/dist/extension.js', 'server/dist/server.js']) {
    if (!entries.includes('extension/' + name)) throw new Error('Missing compiled extension file: ' + name);
  }
}

/** Archive the release commit and checksum the already-built VSIX. */
export function packAssets(repository, directory, version) {
  const [archive, vsix, sums] = assetNames(version);
  if (!fs.existsSync(path.join(directory, vsix))) throw new Error('Build the VSIX before packaging release assets.');
  if (execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], { cwd: repository, encoding: 'utf8' }).trim()) {
    throw new Error('The release source changed during the build.');
  }
  const tar = execFileSync('git', ['archive', '--format=tar', '--prefix=z-' + version + '/', 'HEAD'],
    { cwd: repository, maxBuffer: 64 * 1024 * 1024 });
  fs.writeFileSync(path.join(directory, archive), gzipSync(tar));
  fs.writeFileSync(path.join(directory, sums),
    [archive, vsix].map(name => digest(path.join(directory, name)) + '  ' + name + '\n').join(''));
  verifyAssets(directory, version);
}

/** Match uploaded asset names and server-provided digests to verified local files. */
export function verifyRemoteAssets(release, directory, version, published = false) {
  const names = assetNames(version);
  if (!release || release.tag_name !== 'v' + version || release.prerelease ||
      (published && (release.draft || release.immutable !== true))) {
    throw new Error('Expected a stable ' + (published ? 'immutable published' : 'draft') + ' release.');
  }
  if (!published && !release.draft) throw new Error('A published release must be reused, never overwritten.');
  const uploaded = release.assets ?? [];
  if (uploaded.length !== names.length || new Set(uploaded.map(asset => asset.name)).size !== names.length) {
    throw new Error('The release must contain exactly the source archive, VSIX and checksums.');
  }
  for (const name of names) {
    const asset = uploaded.find(value => value.name === name);
    if (!asset || asset.state !== 'uploaded' || asset.digest !== 'sha256:' + digest(path.join(directory, name))) {
      throw new Error('Missing or mismatched uploaded asset: ' + name);
    }
  }
}

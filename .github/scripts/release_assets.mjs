import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { gzipSync, gunzipSync } from 'node:zlib';
import { assertVersions, parseVersion } from './release_version.mjs';

const SOURCE_LIMIT = 64 * 1024 * 1024;
const VSIX_LIMIT = 128 * 1024 * 1024;

/** 統一したバージョンに必要な成果物一式を返す。 */
export function assetNames(version) {
  parseVersion(version);
  return ['z-' + version + '.tar.gz', 'z-ls-' + version + '.vsix', 'SHA256SUMS'];
}

/** サイズ上限内の通常ファイルを読む。ダウンロードされたシンボリックリンクは辿らない。 */
function readBounded(filename, limit) {
  const info = fs.lstatSync(filename);
  if (!info.isFile() || info.size > limit) throw new Error('Expected a bounded regular release file: ' + path.basename(filename));
  return fs.readFileSync(filename);
}

/** リリース成果物の上限を守りながら、ファイルのSHA256を計算する。 */
export function digest(filename) {
  return createHash('sha256').update(readBounded(filename, VSIX_LIMIT)).digest('hex');
}

/** バージョンコミットの時刻に依存せず、検証済みのソース親コミットの時刻で信頼済みツリーをアーカイブする。 */
export function sourceArchive(repository, version, ref = 'HEAD') {
  parseVersion(version);
  const tree = execFileSync('git', ['rev-parse', ref + '^{tree}'], { cwd: repository, encoding: 'utf8' }).trim();
  const sourceDate = execFileSync('git', ['show', '-s', '--format=%cI', ref + '^'], { cwd: repository, encoding: 'utf8' }).trim();
  return execFileSync('git', ['-c', 'tar.umask=0022', 'archive', '--format=tar', '--mtime=' + sourceDate,
    '--prefix=z-' + version + '/', tree], { cwd: repository, maxBuffer: SOURCE_LIMIT });
}

/** ソースの全バイトを、新たにcheckoutした信頼済みツリーと照合する。 */
export function verifySourceArchive(repository, directory, version, ref = 'HEAD') {
  const [archive] = assetNames(version);
  const source = gunzipSync(readBounded(path.join(directory, archive), SOURCE_LIMIT), { maxOutputLength: SOURCE_LIMIT });
  if (!source.equals(sourceArchive(repository, version, ref))) throw new Error('Source archive does not match the validated Git tree.');
}

/** 通常ファイルの集合、メタデータの上限、JSON/XMLの識別情報、チェックサムを照合する。 */
export function verifyAssets(directory, version) {
  const [archive, vsix, sums] = assetNames(version);
  const names = fs.readdirSync(directory).sort();
  if (JSON.stringify(names) !== JSON.stringify(assetNames(version).sort())) throw new Error('Unexpected release files or directories.');
  const tar = gunzipSync(readBounded(path.join(directory, archive), SOURCE_LIMIT), { maxOutputLength: SOURCE_LIMIT });
  readBounded(path.join(directory, vsix), VSIX_LIMIT);
  const checksums = readBounded(path.join(directory, sums), 4096).toString('utf8');
  const expected = [archive, vsix].map(name => digest(path.join(directory, name)) + '  ' + name + '\n').join('');
  if (checksums !== expected) throw new Error('Release checksums do not match.');
  const readTar = name => execFileSync('tar', ['-xOf', '-', 'z-' + version + '/' + name],
    { input: tar, encoding: 'utf8', maxBuffer: 1024 * 1024 });
  const manifest = JSON.parse(readTar('ls/package.json'));
  assertVersions(readTar('version.zsh'), manifest, JSON.parse(readTar('ls/package-lock.json')), version);
  if (manifest.name !== 'z-ls' || manifest.publisher !== 'milkeclair') throw new Error('Unexpected source extension identity.');
  execFileSync('python3', [path.join(path.dirname(fileURLToPath(import.meta.url)), 'verify_vsix.py'),
    path.join(directory, vsix), version], { maxBuffer: 1024 * 1024 });
}

/** ローカルで準備したツリーをアーカイブし、ビルド済みVSIXのチェックサムを計算する。 */
export function packAssets(repository, directory, version) {
  const [archive, vsix, sums] = assetNames(version);
  if (!fs.existsSync(path.join(directory, vsix))) throw new Error('Build the VSIX before packaging release assets.');
  if (execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], { cwd: repository, encoding: 'utf8' }).trim()) {
    throw new Error('The release source changed during the build.');
  }
  fs.writeFileSync(path.join(directory, archive), gzipSync(sourceArchive(repository, version)));
  fs.writeFileSync(path.join(directory, sums),
    [archive, vsix].map(name => digest(path.join(directory, name)) + '  ' + name + '\n').join(''));
  verifyAssets(directory, version);
  verifySourceArchive(repository, directory, version);
}

/** アップロード済みの名前とサーバーのダイジェストを、検証済みのローカルファイルと照合する。 */
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

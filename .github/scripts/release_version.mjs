import fs from 'node:fs';
import path from 'node:path';

/** z本体とMarketplaceで共用できる、正規化された安定版バージョンを解析する。 */
export function parseVersion(version) {
  const match = typeof version === 'string' && /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.exec(version);
  if (!match || match[0] !== version) throw new Error('Use a stable version such as 2.4.0, without a v prefix.');
  const parts = match.slice(1).map(Number);
  if (!parts.every(Number.isSafeInteger)) throw new Error('Version components exceed the supported integer range.');
  return parts;
}

/** 正規化された安定版のバージョン2つを比較する。 */
export function compareVersions(left, right) {
  const a = parseVersion(left), b = parseVersion(right);
  for (let index = 0; index < a.length; index++) {
    if (a[index] !== b[index]) return a[index] < b[index] ? -1 : 1;
  }
  return 0;
}

/** 古いDraftの復旧によってLatestリリースが過去の版へ戻らないようにする。 */
export function shouldMakeLatest(version, latestTag) {
  parseVersion(version);
  if (latestTag === null) return true;
  return compareVersions(version, latestTag.replace(/^v/, '')) > 0;
}

/** 他の補助関数を変更せず、管理対象のz.version関数を見つける。 */
function versionMatch(source) {
  const matches = [...source.matchAll(/(^z\.version\(\)\s*\{\s*z\.io ")v([^"\r\n]+)("\s*\})/gm)];
  if (matches.length !== 1) throw new Error('Expected one managed z.version function in version.zsh.');
  parseVersion(matches[0][2]);
  return matches[0];
}

/** version.zshに記載されたリリースバージョンを読む。 */
export function sourceVersion(source) {
  return versionMatch(source)[2];
}

/** ソース、npmメタデータ、lockfileのバージョンが一致することを要求する。 */
export function assertVersions(source, manifest, lock, version) {
  parseVersion(version);
  if (sourceVersion(source) !== version || manifest.version !== version ||
      lock.version !== version || lock.packages?.['']?.version !== version) {
    throw new Error('Source, extension manifest and lockfile must share version ' + version + '.');
  }
}

export const VERSION_FILES = Object.freeze(['version.zsh', 'ls/package.json', 'ls/package-lock.json']);

/** 入力やファイルを変更せず、許可されたメタデータ変更を正確に計算する。 */
export function versionFiles(source, manifestText, lockText, version) {
  parseVersion(version);
  const manifest = JSON.parse(manifestText), lock = JSON.parse(lockText);
  if (manifest.version !== lock.version || manifest.version !== lock.packages?.['']?.version) {
    throw new Error('Repair the existing package/lockfile version mismatch before releasing.');
  }
  if (compareVersions(version, manifest.version) <= 0 || compareVersions(version, sourceVersion(source)) <= 0) {
    throw new Error('A new release must be newer than both current component versions.');
  }
  const match = versionMatch(source);
  const updated = source.slice(0, match.index) + match[1] + 'v' + version + match[3] +
    source.slice(match.index + match[0].length);
  const nextManifest = { ...manifest, version };
  const nextLock = { ...lock, version, packages: { ...lock.packages, '': { ...lock.packages[''], version } } };
  assertVersions(updated, nextManifest, nextLock, version);
  return {
    'version.zsh': updated,
    'ls/package.json': JSON.stringify(nextManifest, null, 2) + '\n',
    'ls/package-lock.json': JSON.stringify(nextLock, null, 2) + '\n',
  };
}

/** 新しいリリースに必要なバージョンファイルの変更だけを書き込む。 */
export function updateVersions(directory, version) {
  const texts = VERSION_FILES.map(name => fs.readFileSync(path.join(directory, name), 'utf8'));
  for (const [name, content] of Object.entries(versionFiles(...texts, version))) {
    fs.writeFileSync(path.join(directory, name), content);
  }
}

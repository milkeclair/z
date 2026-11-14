import fs from 'node:fs';
import path from 'node:path';

/** Parse a canonical stable version that both z and the Marketplace can use. */
export function parseVersion(version) {
  const match = typeof version === 'string' && /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.exec(version);
  if (!match || match[0] !== version) throw new Error('Use a stable version such as 2.4.0, without a v prefix.');
  const parts = match.slice(1).map(Number);
  if (!parts.every(Number.isSafeInteger)) throw new Error('Version components exceed the supported integer range.');
  return parts;
}

/** Compare two canonical stable versions. */
export function compareVersions(left, right) {
  const a = parseVersion(left), b = parseVersion(right);
  for (let index = 0; index < a.length; index++) {
    if (a[index] !== b[index]) return a[index] < b[index] ? -1 : 1;
  }
  return 0;
}

/** Keep recovery of an older draft from moving the Latest release backwards. */
export function shouldMakeLatest(version, latestTag) {
  parseVersion(version);
  if (latestTag === null) return true;
  return compareVersions(version, latestTag.replace(/^v/, '')) > 0;
}

/** Locate the managed z.version function without changing the remaining helpers. */
function versionMatch(source) {
  const matches = [...source.matchAll(/(^z\.version\(\)\s*\{\s*z\.io ")v([^"\r\n]+)("\s*\})/gm)];
  if (matches.length !== 1) throw new Error('Expected one managed z.version function in version.zsh.');
  parseVersion(matches[0][2]);
  return matches[0];
}

/** Read the release version embedded in version.zsh. */
export function sourceVersion(source) {
  return versionMatch(source)[2];
}

/** Require matching versions in source, npm metadata and its lockfile. */
export function assertVersions(source, manifest, lock, version) {
  parseVersion(version);
  if (sourceVersion(source) !== version || manifest.version !== version ||
      lock.version !== version || lock.packages?.['']?.version !== version) {
    throw new Error('Source, extension manifest and lockfile must share version ' + version + '.');
  }
}

/** Update only the three version-bearing files before creating a release commit. */
export function updateVersions(directory, version) {
  parseVersion(version);
  const sourcePath = path.join(directory, 'version.zsh');
  const source = fs.readFileSync(sourcePath, 'utf8');
  const manifestPath = path.join(directory, 'ls/package.json');
  const lockPath = path.join(directory, 'ls/package-lock.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
  if (manifest.version !== lock.version || manifest.version !== lock.packages?.['']?.version) {
    throw new Error('Repair the existing package/lockfile version mismatch before releasing.');
  }
  if (compareVersions(version, manifest.version) <= 0 || compareVersions(version, sourceVersion(source)) <= 0) {
    throw new Error('A new release must be newer than both current component versions.');
  }
  const match = versionMatch(source);
  const updated = source.slice(0, match.index) + match[1] + 'v' + version + match[3] +
    source.slice(match.index + match[0].length);
  manifest.version = version;
  lock.version = version;
  lock.packages[''].version = version;
  assertVersions(updated, manifest, lock, version);
  fs.writeFileSync(sourcePath, updated);
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  fs.writeFileSync(lockPath, JSON.stringify(lock, null, 2) + '\n');
}

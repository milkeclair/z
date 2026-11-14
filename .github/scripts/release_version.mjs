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

export const VERSION_FILES = Object.freeze(['version.zsh', 'ls/package.json', 'ls/package-lock.json']);

/** Calculate the exact allowed metadata edits without modifying inputs or the filesystem. */
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

/** Write only the exact version-file edits for a new release. */
export function updateVersions(directory, version) {
  const texts = VERSION_FILES.map(name => fs.readFileSync(path.join(directory, name), 'utf8'));
  for (const [name, content] of Object.entries(versionFiles(...texts, version))) {
    fs.writeFileSync(path.join(directory, name), content);
  }
}

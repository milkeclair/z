import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { assertVersions, compareVersions, parseVersion, sourceVersion, updateVersions, shouldMakeLatest, VERSION_FILES, versionFiles } from './release_version.mjs';
import { assetNames, packAssets, verifyAssets, verifyRemoteAssets, verifySourceArchive } from './release_assets.mjs';

/** Read a command result without invoking a shell. */
function read(command, args, directory) {
  return execFileSync(command, args, { cwd: directory, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 }).trim();
}

/** Run a command while preserving its status and normal terminal output. */
function run(command, args, directory) {
  execFileSync(command, args, { cwd: directory, stdio: 'inherit' });
}

/** Validate a GitHub repository name before forming API paths. */
function repositoryName(repository) {
  if (!/^[A-Za-z0-9_-]+\/[A-Za-z0-9_.-]+$/.test(repository)) throw new Error('Expected owner/repository.');
  return repository;
}

/** Supply credentials only through gh's standard Git credential helper. */
function gitAuthentication() {
  return ['-c', 'credential.helper=', '-c', 'credential.helper=!gh auth git-credential'];
}

/** Read release metadata; authentication and network failures remain errors. */
function getApi(endpoint) {
  try {
    return JSON.parse(read('gh', ['api', endpoint]));
  } catch (error) {
    if (error.stderr?.toString().includes('HTTP 404')) return null;
    throw error;
  }
}

/** Resolve pending and published tags through gh's draft-aware release lookup. */
function getRelease(repository, version) {
  try {
    const release = JSON.parse(read('gh', ['release', 'view', 'v' + version, '--repo', repositoryName(repository),
      '--json', 'tagName,isDraft,isPrerelease,isImmutable,assets,body,databaseId']));
    return { tag_name: release.tagName, draft: release.isDraft, prerelease: release.isPrerelease,
      immutable: release.isImmutable, assets: release.assets, body: release.body, id: release.databaseId };
  } catch (error) {
    if (error.stderr?.toString().trim() === 'release not found') return null;
    throw error;
  }
}

/** Require a server-enforced, branch-only main policy for the OIDC environment. */
export function assertMarketplaceEnvironment(environment, policies) {
  const policy = environment?.deployment_branch_policy;
  if (!policy || policy.protected_branches !== false || policy.custom_branch_policies !== true ||
      policies.length !== 1 || policies[0].name !== 'main' || policies[0].type !== 'branch') {
    throw new Error('Configure the marketplace environment to allow only branch main before enabling OIDC publishing.');
  }
}

/** Read environment controls without changing any repository settings. */
function checkMarketplaceEnvironment(repository) {
  const base = 'repos/' + repositoryName(repository) + '/environments/marketplace';
  const environment = getApi(base);
  if (!environment) throw new Error('Create the main-only marketplace environment before publishing.');
  const pages = JSON.parse(read('gh', ['api', '--paginate', '--slurp', base + '/deployment-branch-policies?per_page=100']));
  assertMarketplaceEnvironment(environment, pages.flatMap(page => page.branch_policies ?? []));
}

/** Read the three version files from a specific commit. */
function assertCommitVersions(directory, ref, version) {
  const show = filename => read('git', ['show', ref + ':' + filename], directory);
  assertVersions(show('version.zsh'), JSON.parse(show('ls/package.json')), JSON.parse(show('ls/package-lock.json')), version);
}

/** Require a single-parent commit containing only the exact generated version-file edits. */
export function assertVersionCommit(directory, version, ref = 'HEAD', expectedParent = null) {
  const parents = read('git', ['rev-list', '--parents', '-n', '1', ref], directory).split(/\s+/);
  if (parents.length !== 2 || (expectedParent && parents[1] !== expectedParent)) {
    throw new Error('The version commit must have the validated source as its only parent.');
  }
  const blob = (revision, name) => execFileSync('git', ['show', revision + ':' + name], { cwd: directory, maxBuffer: 16 * 1024 * 1024 });
  const expected = versionFiles(...VERSION_FILES.map(name => blob(parents[1], name).toString('utf8')), version);
  const changed = execFileSync('git', ['diff', '--name-only', '-z', parents[1], ref], { cwd: directory })
    .toString('utf8').split('\0').filter(Boolean).sort();
  if (JSON.stringify(changed) !== JSON.stringify([...VERSION_FILES].sort())) {
    throw new Error('The version commit changes files outside the version-bearing metadata.');
  }
  for (const [name, content] of Object.entries(expected)) {
    const mode = revision => read('git', ['ls-tree', revision, '--', name], directory).split(/\s/)[0];
    if (!blob(ref, name).equals(Buffer.from(content)) || mode(ref) !== mode(parents[1])) {
      throw new Error('Unexpected content or mode in version-bearing metadata: ' + name);
    }
  }
}

/** Choose creation, draft/tag recovery, or immutable-asset reuse. */
export function planRelease(directory, version, repository, sourceSha, action = 'draft') {
  parseVersion(version);
  repositoryName(repository);
  if (!['draft', 'publish'].includes(action)) throw new Error('Expected draft or publish action.');
  if (read('git', ['rev-parse', 'HEAD'], directory) !== sourceSha) throw new Error('Checkout must match the dispatched source commit.');
  read('git', [...gitAuthentication(), 'fetch', '--tags', 'origin', 'refs/heads/main:refs/remotes/origin/main'], directory);
  const release = getRelease(repository, version);
  if (release && !release.draft) {
    if (release.immutable !== true) throw new Error('Existing release is not immutable.');
    if (action === 'draft') throw new Error('This version is already published; use release-publish to reuse it.');
    return 'published';
  }
  if (action === 'publish') {
    if (!release) throw new Error('Run release-draft first, then enter and save its release notes.');
    releaseNotes(release.body);
  }
  const tag = 'v' + version;
  const found = spawnSync('git', ['rev-parse', '--quiet', '--verify', 'refs/tags/' + tag], { cwd: directory });
  if (found.status === 0) {
    run('git', ['merge-base', '--is-ancestor', tag, 'refs/remotes/origin/main'], directory);
    assertCommitVersions(directory, tag, version);
    assertVersionCommit(directory, version, tag);
    return 'resume';
  }
  if (found.status !== 1) throw new Error('Unable to inspect the existing release tag.');
  if (release) throw new Error('Draft release has no source tag; review it before retrying.');
  if (read('git', ['rev-parse', 'origin/main'], directory) !== sourceSha) throw new Error('main advanced; dispatch a new workflow run.');
  const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'ls/package.json'), 'utf8'));
  if (compareVersions(version, manifest.version) <= 0 ||
      compareVersions(version, sourceVersion(fs.readFileSync(path.join(directory, 'version.zsh'), 'utf8'))) <= 0) {
    throw new Error('Choose a version newer than both current component versions.');
  }
  return 'new';
}

/** Create only a local release commit/tag, or select the existing unpublished tag. */
export function prepareRelease(directory, version, mode, sourceSha) {
  parseVersion(version);
  if (mode === 'resume') {
    if (read('git', ['rev-parse', 'v' + version + '^{commit}'], directory) !== sourceSha) {
      throw new Error('Release tag changed after validation; dispatch a new workflow run.');
    }
    run('git', ['checkout', '--detach', 'v' + version], directory);
    assertCommitVersions(directory, 'HEAD', version);
    return;
  }
  if (mode !== 'new') throw new Error('Only new or resumable releases need preparation.');
  if (read('git', ['rev-parse', 'HEAD'], directory) !== sourceSha ||
      read('git', ['status', '--porcelain', '--untracked-files=no'], directory)) throw new Error('Release source must be clean and match the dispatched commit.');
  updateVersions(directory, version);
  run('git', ['add', '--', 'version.zsh', 'ls/package.json', 'ls/package-lock.json'], directory);
  const identity = ['-c', 'user.name=github-actions[bot]', '-c', 'user.email=41898282+github-actions[bot]@users.noreply.github.com'];
  run('git', [...identity, 'commit', '-m', 'release: v' + version], directory);
  run('git', [...identity, 'tag', '--annotate', 'v' + version, '--message', 'Release v' + version], directory);
}

/** Compare-and-swap main and tag; the checked single parent makes the main update a fast-forward. */
export function pushRelease(directory, version, sourceSha) {
  parseVersion(version);
  assertVersionCommit(directory, version, 'HEAD', sourceSha);
  const remote = read('git', [...gitAuthentication(), 'ls-remote', 'origin', 'refs/heads/main'], directory).split(/\s/)[0];
  if (remote !== sourceSha || read('git', ['rev-parse', 'HEAD^'], directory) !== sourceSha) {
    throw new Error('main advanced; nothing was pushed. Dispatch a new workflow run.');
  }
  if (read('git', ['rev-parse', 'v' + version + '^{commit}'], directory) !== read('git', ['rev-parse', 'HEAD'], directory)) {
    throw new Error('Local release tag does not match the release commit.');
  }
  run('git', [...gitAuthentication(), 'push', '--atomic', '--force-with-lease=refs/heads/main:' + sourceSha, 'origin', 'HEAD:refs/heads/main', 'refs/tags/v' + version], directory);
}

/** Detect a moved remote tag before and after the publication boundary. */
export function assertRemoteTag(directory, version, expectedRef = 'HEAD') {
  parseVersion(version);
  const tag = 'refs/tags/v' + version;
  const refs = read('git', [...gitAuthentication(), 'ls-remote', 'origin', tag, tag + '^{}'], directory)
    .split('\n').map(line => line.split(/\s+/));
  const commit = refs.find(([, name]) => name === tag + '^{}')?.[0] ?? refs.find(([, name]) => name === tag)?.[0];
  if (commit !== read('git', ['rev-parse', expectedRef], directory)) {
    throw new Error('Remote release tag changed; stop and review the release.');
  }
}

/** Download and verify original release assets, requiring immutable state by default. */
export function downloadRelease(repository, version, directory, sourceDirectory = process.cwd(), published = true) {
  parseVersion(version);
  const release = getRelease(repository, version);
  if (!release || (published ? release.draft || release.immutable !== true : !release.draft)) {
    throw new Error(published ? 'An immutable published release is required.' : 'An unpublished draft release is required.');
  }
  read('git', [...gitAuthentication(), 'fetch', '--no-tags', 'origin', 'refs/tags/v' + version + ':refs/tags/v' + version], sourceDirectory);
  fs.mkdirSync(directory, { recursive: true });
  run('gh', ['release', 'download', 'v' + version, '--repo', repository, '--dir', directory,
    ...assetNames(version).flatMap(name => ['--pattern', name])]);
  verifySourceArchive(sourceDirectory, directory, version, 'v' + version);
  verifyAssets(directory, version);
  verifyRemoteAssets(release, directory, version, published);
}

/** Require author-written release notes while preserving their Markdown verbatim. */
export function releaseNotes(notes) {
  if (typeof notes !== 'string' || !notes.trim()) throw new Error('Release notes are required; write and save non-empty Markdown in the draft body.');
  return notes;
}

/** Upload and verify all assets while keeping the draft editable for release notes. */
export function stageRelease(directory, version, repository, assets, mode, sourceSha) {
  parseVersion(version);
  verifySourceArchive(directory, assets, version);
  verifyAssets(assets, version);
  if (mode === 'new') pushRelease(directory, version, sourceSha);
  else if (mode !== 'resume') throw new Error('Published releases must be downloaded rather than rebuilt.');
  const tag = 'v' + version;
  let release = getRelease(repository, version);
  if (release && !release.draft) throw new Error('Release was published concurrently; retry to reuse its original assets.');
  if (!release) {
    run('gh', ['release', 'create', tag, '--repo', repository, '--draft', '--verify-tag',
      '--target', read('git', ['rev-parse', 'HEAD'], directory), '--title', tag, '--notes', '']);
  }
  run('gh', ['release', 'upload', tag, '--repo', repository, '--clobber',
    ...assetNames(version).map(name => path.join(assets, name))]);
  release = getRelease(repository, version);
  verifyRemoteAssets(release, assets, version);
  assertRemoteTag(directory, version);
}

/** Publish the verified draft assets and saved Markdown without rebuilding or pushing. */
export function publishRelease(directory, version, repository, assets, notesFile, sourceSha) {
  parseVersion(version);
  const draft = getRelease(repository, version);
  if (!draft || !draft.draft) throw new Error('An unpublished draft release is required.');
  const notes = releaseNotes(draft.body);
  downloadRelease(repository, version, assets, directory, false);
  const tag = 'v' + version;
  if (read('git', ['rev-parse', tag + '^{commit}'], directory) !== sourceSha) {
    throw new Error('Release tag changed after validation; dispatch a new workflow run.');
  }
  run('git', ['merge-base', '--is-ancestor', tag, 'origin/main'], directory);
  assertCommitVersions(directory, tag, version);
  assertVersionCommit(directory, version, tag);
  const current = getRelease(repository, version);
  verifyRemoteAssets(current, assets, version);
  if (current.id !== draft.id || current.body !== notes) throw new Error('Draft changed during validation; retry publication.');
  assertRemoteTag(directory, version, sourceSha);
  fs.writeFileSync(notesFile, notes, 'utf8');
  const latest = getApi('repos/' + repositoryName(repository) + '/releases/latest');
  const latestFlag = shouldMakeLatest(version, latest?.tag_name ?? null) ? '--latest' : '--latest=false';
  run('gh', ['release', 'edit', tag, '--repo', repository, '--draft=false', latestFlag, '--notes-file', notesFile]);
  verifyRemoteAssets(getRelease(repository, version), assets, version, true);
  assertRemoteTag(directory, version, sourceSha);
}

/** Dispatch workflow commands using explicit arguments instead of interpolated shell code. */
function main(command, version, ...args) {
  const root = process.cwd();
  switch (command) {
    case 'environment': {
      checkMarketplaceEnvironment(version);
      return;
    }
    case 'plan': {
      const [repository, sourceSha, action] = args;
      console.log(planRelease(root, version, repository, sourceSha, action));
      return;
    }
    case 'prepare': {
      const [mode, validatedSha] = args;
      prepareRelease(root, version, mode, validatedSha);
      return;
    }
    case 'pack': {
      const [directory] = args;
      packAssets(root, directory, version);
      return;
    }
    case 'stage': {
      const [repository, sourceSha, directory, mode] = args;
      stageRelease(root, version, repository, directory, mode, sourceSha);
      return;
    }
    case 'publish': {
      const [repository, directory, notesFile, sourceSha] = args;
      publishRelease(root, version, repository, directory, notesFile, sourceSha);
      return;
    }
    case 'download': {
      const [repository, directory] = args;
      downloadRelease(repository, version, directory);
      return;
    }
    default: throw new Error('Expected environment, plan, prepare, pack, stage, publish or download.');
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    main(...process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

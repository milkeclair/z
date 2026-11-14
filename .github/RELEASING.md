# Releasing z and z-ls

## Run a release

1. Open Actions → release-draft → Run workflow on main and enter a stable version
   such as 2.4.0 (without v). This builds and verifies the source archive and VSIX,
   pushes the version commit/tag, and saves a draft GitHub Release.
2. Open Releases, edit the prepared draft, write the multiline Markdown in
   "Release description", and click Save draft. The workflow starts with an
   empty body so that you can write the release notes yourself.
3. Open Actions → release-publish → Run workflow on main. Enter the same version
   and choose whether to publish to Visual Studio Marketplace. It downloads the
   draft's existing artifacts, validates them and the saved body, and publishes
   the release without rebuilding. Empty or whitespace-only notes stop publication.

Both forms use single-line version fields; the Markdown is edited in GitHub's
release editor, which supports multiple lines and a preview. No release notes are
generated. Use Save draft in the editor, then release-publish to run the final
validation and optional Marketplace publication.

The publishing workflow keeps the filename release.yml because Marketplace's
Trusted Publishing policy is bound to that filename. The draft workflow is
release-draft.yml. From the CLI, their display names work as well:

```sh
gh workflow run release-draft --ref main -f version=2.4.0
# Edit and save the prepared draft body in GitHub.
gh workflow run release-publish --ref main -f version=2.4.0 -F publish_marketplace=false
```

The version applies to z.version, ls/package.json and ls/package-lock.json.
The first unified release must be newer than the existing z-ls version 2.3.0.
Every new release must advance both component versions. Prereleases and build
metadata are currently outside this workflow.

release-draft validates the request, runs the existing Zsh/LSP CI, and creates a
local version commit and annotated vVERSION tag in a read-only build job. That job
builds the VSIX and packages all tracked source, including lib, mod, tests and LSP
source. A separate contents-write job executes no npm install or build code. It
recreates the three exact metadata edits from trusted source, checks the full
source archive against that tree, then pushes main and the tag atomically.
The checked single parent makes this a fast-forward; an explicit lease also
requires main to retain the dispatched SHA until the push.

It attaches these assets to a draft GitHub Release, verifies the uploaded SHA256
digests, and stops with the draft editable. release-publish downloads and verifies
the same bytes, source/version commit, tag and saved Markdown before publishing.
VSIX JSON and XML must agree on extension ID, publisher, version and stable channel; source contents must match the trusted Git
tree. The source tar uses the validated source parent's timestamp and fixed permissions,
so independently recreated version commits produce the same archive contents:

- z-VERSION.tar.gz
- z-ls-VERSION.vsix
- SHA256SUMS

GitHub's immutable releases setting must stay enabled. It is already enabled for
milkeclair/z. Publication fixes the tag and asset bytes; the workflow also verifies
the published release's immutable flag. Correct a published release with a new
version. Draft-aware publication validation runs in the existing contents-write
publishing job because GitHub requires push access to see drafts. The read-only preflight
checks the dispatch branch, locked Actions and optional Marketplace controls.
The GITHUB_TOKEN needs contents: write for the draft/publishing jobs, and branch
rules must permit its version commit on main. A rejected atomic push changes
neither main nor the tag.

The draft workflow reuses CI from the same commit through a local workflow
reference. External Actions are pinned by actions.lock.

## Optional Marketplace publication

The release-publish checkbox defaults to false. The VSIX is attached to GitHub in
either case.
When selected, the publishing job downloads the already-published immutable
assets, verifies their checksums, versions and extension identity, then runs:

```sh
./node_modules/.bin/vsce publish --oidc --packagePath /path/to/z-ls-VERSION.vsix
```

This publishes the same VSIX without rebuilding it. Only this job requests
id-token: write. No Marketplace PAT or repository secret is required. The job is
bound to the marketplace environment, and branch restrictions are enforced by
GitHub rather than relying only on workflow conditionals.

Before the first Marketplace publication:

1. In repository Settings → Environments, create marketplace. Under deployment
   branches and tags, allow exactly one rule: branch main. Use selected branches,
   with no wildcard, tag rule or additional allowed branch.
2. Keep these controls in place. Preflight and the publishing job read them with
   actions: read and reject a missing or broader environment.
3. An owner of publisher milkeclair creates this Trusted Publishing policy at the
[Marketplace publisher management page](https://marketplace.visualstudio.com/manage):

| Field | Value |
| --- | --- |
| Policy name | z release workflow |
| Repository owner | milkeclair |
| Repository | z |
| Workflow | release.yml |
| Environment | marketplace |

The workflow accepts release dispatches only from main. Bind the policy to the
configured environment; leaving its Environment field empty would also trust
matching workflow files on other branches.

## Recover a failed run

If main advances while release-draft is validating/building, the push is rejected.
Start a new release-draft dispatch from current main to include the latest changes.

If the version commit/tag were pushed but draft preparation failed, run
release-draft again with the same version. It checks that the tag belongs to main
and contains matching source/manifest/lock versions, then runs CI against that tag
and resumes from it. A tag change after validation requires a new dispatch.
Retrying draft preparation preserves its saved body. The three expected draft
assets may be replaced before publication; unexpected extra assets cause a failure
for manual review.

If release-publish fails, correct the draft notes or reported issue and run it
again. Publication downloads the existing draft assets; it does not rebuild,
replace assets or update main. A change to the draft body during validation causes
a failure so that the next run uses the newly saved text. Publishing an older
draft preserves a newer release's Latest designation.

Once the GitHub release is immutable, run release-publish with the same version to
verify and reuse its existing assets. Select the Marketplace checkbox to retry
that publication or publish a version initially released only on GitHub. The
existing body, tag and assets are preserved; no notes input is needed on retries.
Marketplace duplicate-version errors remain errors rather than being silently
accepted.

GitHub and Marketplace are separate services. A Marketplace failure leaves the
immutable GitHub release published and available for retry.

## Install a versioned release

Download the source archive and SHA256SUMS from the GitHub release, verify its
SHA256 entry, extract the archive, and point Z_ROOT at the extracted z-VERSION
directory before sourcing main.zsh. Mod source is included in the same archive.
Install the matching VSIX manually or select the version in Marketplace.

The existing z.install command continues to install the main branch. Use the
release assets when you need the fixed contents of a specific version.

## Local verification

```sh
node --test .github/scripts/release.test.mjs
cd ls
npm ci
npm test -- --maxWorkers=2
```

Asset validation accepts exactly three regular files, caps source expansion at
64 MiB, VSIX size at 128 MiB, and VSIX expanded contents at 512 MiB. Metadata is
limited to 1 MiB per file. Duplicate/unsafe ZIP paths, symlinks, DTDs and unexpected
identities are rejected before publication. This validates packaging and source
association; the reviewed main code and locked build toolchain remain trusted.

The release tests use temporary real Git repositories to verify version updates,
atomic pushes, conflicting refs and artifact checks. GitHub API states are
fixtures; these tests do not publish GitHub releases or Marketplace extensions.

References:
[GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases),
[Marketplace Trusted Publishing](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#publish-with-github-actions-and-trusted-publishing).

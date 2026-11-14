# z-ls

## Server memory behavior

The VS Code client starts the server with
`--no-allocation-site-pretenuring` in both run and debug mode. Initial indexing
and repeated edits share token allocation sites, so this prevents short-lived
edit data from being allocated directly in old space. Normal young-to-old
promotion remains enabled. The flag applies only to the language server process.

For a standalone server started from this directory, use the same option:

```sh
node --no-allocation-site-pretenuring server/dist/server.js --stdio
```

## Development checks

Use Node.js 24 and make Zsh available on PATH. From this directory:

```sh
npm ci
npm test -- --maxWorkers=2
```

The test command cleans build output, compiles the client and server, checks test
types, and runs the full Vitest suite. Integration tests start the emitted Node
server and real Zsh processes. Two workers bound test concurrency.

The repository CI runs these checks after the Zsh library tests, using the same
source-built Zsh version. The Node setup caches npm downloads using
`package-lock.json`; `npm ci` installs the locked dependency tree on every run.

## Dependency changes

Commit `package-lock.json` together with changes to `package.json`.
Use `npm install` to update the lockfile when intentionally changing dependencies,
then run the checks above from a clean installation.

## Package the extension

From this directory, run `npm run package`. It installs the locked dependencies
with `npm ci` and creates a VSIX after the prepublish build.

## Releases

z and z-ls share the version selected in the repository [release workflow](../.github/RELEASING.md).
Every GitHub release includes a versioned VSIX; Marketplace publication is an optional OIDC-authenticated job.

# z-ls

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

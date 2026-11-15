# pj

Register named project directories and open them in Visual Studio Code.

## Install

```zsh
z.install.mod pj
```

The mod uses the core z library and the `code` command on PATH. Update the core
with `z.update` before installing this mod when it does not yet provide
`z.arg.named.literal`, `z.file.write.literal` and `z.io.literal`.

## Commands

```zsh
z.pj.add name=some_project dir=~/repo/p/some
z.pj.add name=other_project dir="/path/with spaces"
z.pj.list
z.pj some_project
z.pj.remove some_project
z.pj.remove
```

`add` stores an existing directory as an absolute, symlink-resolved path. Relative
paths and a leading `~/` are accepted. Project names start with an ASCII letter,
digit or underscore and may then contain letters, digits, underscores, hyphens
and dots. Existing names are rejected; remove a registration before replacing it.
Names such as `true`, `false` and `null` are kept literally. Directory paths
containing newlines are rejected.

`list` prints names and directories separated by a tab, sorted by name. An empty
registry prints `No projects registered.`

`z.pj <name>` passes the saved directory as one argument to `code`. The caller's
working directory stays the same. Missing registrations, directories that no
longer exist and unavailable editor commands fail with an error. The editor's
exit status is returned.

`remove <name>` removes only that registration file. With no argument, `remove`
shows numbered names and asks for a project number. Empty input or end-of-file
cancels successfully. An invalid number reports an error and preserves the
registry. Project directories and their contents remain in place.

## Persistence

Registrations are stored as plain directory paths, one file per project:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/z/pj/<name>
```

The mod creates this directory when adding the first project. Reading or opening
projects and cancelling a selection do not create settings files. Stored paths
are read as data and never sourced or evaluated. Symbolic links in place of
registration files are rejected.

Tests use temporary configuration and project directories. No background process
or extra package is required.

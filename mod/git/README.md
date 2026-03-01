# z.git

A modifier for git operations.
Provides conventional commit messages, branch management, author statistics, and more.

## Installation

`z.install.mod git`

## Overview

`z.git` acts as a wrapper around git commands.
Undefined subcommands are delegated to `git` as-is.

```zsh
z.git status   # => git status
z.git diff     # => git diff
```

## Commands

### add

- `z.git.add`
  - safer `git add` that rejects `git add .` to encourage explicit file specification

```zsh
z.git.add file1.txt file2.txt  # OK
z.git.add .                    # NG
```

### branch

- `z.git.branch` / `z.git.b`
  - alias for `git branch`
- `z.git.branch.all` / `z.git.b.a`
  - alias for `git branch -a`

```zsh
z.git.b
z.git.b.a
```

- `z.git.branch.current`
  - display the current branch name

```zsh
z.git.branch.current  #=> "main"
```

### commit

- `z.git.commit` / `z.git.c`
  - commit
- `z.git.commit.tdd` / `z.git.c.r` / `z.git.c.g`
  - tdd commit with red/green cycle tag
- `z.git.commit.help`
  - display commit usage

```zsh
z.git.c feat "add new feature"
# => feat: add new feature

z.git.c fix "resolve bug" TICKET-123
# => fix: #TICKET-123 resolve bug
```

If ticket is omitted (without `-nt`), it is automatically extracted from the branch name.
For example, on branch `feature/some-description-123`, `123` is used as the ticket number.

TDD commits include a cycle tag in the message.

```zsh
z.git.c.r test "add failing test" TICKET-123
# => test: #TICKET-123 [red] add failing test

z.git.c.g test "make test pass" TICKET-123
# => test: #TICKET-123 [green] make test pass
```

### fetch

- `z.git.fetch`
  - run `git fetch --prune`

### log

- `z.git.log`
  - display user info and a pretty-formatted commit log

```zsh
z.git.log
# => * <hash> [<date>] <author> <refs>
# =>   <message>
```

### merge

- `z.git.merge`
  - safer merge that rejects dirty working tree and runs `fetch --prune` before merging

```zsh
z.git.merge main
```

### pull

- `z.git.pull`
  - pull based on the current branch context

```zsh
z.git.pull                  # auto-detect
z.git.pull origin develop   # delegate to git pull as-is
z.git.pull dev              # pull from develop branch
```

Behavior:

- If arguments contain `origin`, delegate to `git pull` as-is
- If arguments contain `dev` or `develop`, run `git pull origin develop`
- If current branch is `pr/<number>`, run `git pull origin pull/<number>/head:<branch>`
- Otherwise, run `git pull origin <current_branch>`

### push

- `z.git.push`
  - push based on the current branch context

```zsh
z.git.push                  # auto-detect
z.git.push origin develop   # delegate to git push as-is
```

Behavior:

- If arguments contain `origin`, delegate to `git push` as-is
- If current branch is `pr/<number>`, run `git push origin HEAD:refs/pull/<number>/head`
- Otherwise, run `git push --set-upstream origin <current_branch>`

### stats

- `z.git.stats`
  - display per-author commit statistics in a table

```zsh
z.git.stats
z.git.stats exclude_exts="md txt" exclude_dirs="docs tests"
```

- `exclude_exts`: file extensions to exclude (default: `log`, `lock`)
- `exclude_dirs`: directories to exclude (default: `node_modules`, `dist`)

```
┌──────────────────────┬────────────┬────────────┬────────────┬────────────┐
│ author               │ commit     │ add        │ delete     │ total      │
├──────────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Alice                │ 120        │ 5000       │ 2000       │ 7000       │
├──────────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Bob                  │ 80         │ 3000       │ 1500       │ 4500       │
└──────────────────────┴────────────┴────────────┴────────────┴────────────┘
```

### status

- `z.git.status`
  - display `git status --short` with upstream ahead info

```zsh
z.git.status
# => 'origin/main' by 2 commits.
# => M modified_file.txt
```

### user

- `z.git.user`
  - display local and global git user info
- `z.git.user.local`
  - display local git user info
- `z.git.user.global`
  - display global git user info

```zsh
z.git.user
# => --- local user info ---
# => user.name: milkeclair
# => user.email: milkeclair@example.com
# =>
# => --- global user info ---
# => user.name: milkeclair
# => user.email: milkeclair@example.com
```

- `z.git.user.set` / `z.git.user.set.local`
  - set local git user info
- `z.git.user.set.global`
  - set global git user info

Both require `user.name` and `user.email` as arguments.

```zsh
z.git.user.set "milkeclair" "milkeclair@example.com"
z.git.user.set.global "milkeclair" "milkeclair@example.com"
```

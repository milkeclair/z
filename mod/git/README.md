# z.git

Git操作用のmodです。規約に沿ったコミットメッセージ、ブランチ管理、作成者ごとの統計などを提供します。

## インストール

`z.install.mod git`

## 概要

`z.git`はGitコマンドのラッパーです。定義されていないサブコマンドは、そのまま`git`へ渡します。

```zsh
z.git status   # => git status
z.git diff     # => git diff
```

## コマンド

### add

- `z.git.add`
  - `git add .`を拒否し、ファイルを明示的に指定するようにしたgit addです。

```zsh
z.git.add file1.txt file2.txt  # OK
z.git.add .                    # NG
```

### branch

- `z.git.branch` / `z.git.b`
  - `git branch`の別名
- `z.git.branch.all` / `z.git.b.a`
  - `git branch -a`の別名

```zsh
z.git.b
z.git.b.a
```

- `z.git.branch.current`
  - 現在のブランチ名を表示します。

```zsh
z.git.branch.current  #=> "main"
```

- `z.git.branch.label.current`
  - 現在のブランチのラベルを返します。
  - HEADがdetachedの場合は`detached-<short HEAD>`を返します。
- `z.git.branch.label.for <path>`
  - worktreeパスに対応するブランチのラベルを返します。
  - そのパスがdetachedの場合は`detached-<short HEAD>`を返します。

```zsh
z.git.branch.label.current
echo $REPLY  #=> "main"

z.git.branch.label.for /path/to/worktree
echo $REPLY  #=> "feature/example"
```

### commit

- `z.git.commit` / `z.git.c`
  - コミットします。
- `z.git.commit.tdd` / `z.git.c.r` / `z.git.c.g`
  - red/greenサイクルのタグを付けてTDDのコミットを作成します。
- `z.git.commit.help`
  - コミットの使い方を表示します。

```zsh
z.git.c feat "add new feature"
# => feat: add new feature

z.git.c fix "resolve bug" TICKET-123
# => fix: #TICKET-123 resolve bug
```

チケット番号を省略し、`-nt`も指定しなかった場合は、ブランチ名から自動で取り出します。例えば`feature/some-description-123`では、`123`をチケット番号として使います。

TDDのコミットメッセージにはサイクルのタグを付けます。

```zsh
z.git.c.r test "add failing test" TICKET-123
# => test: #TICKET-123 [red] add failing test

z.git.c.g test "make test pass" TICKET-123
# => test: #TICKET-123 [green] make test pass
```

### fetch

- `z.git.fetch`
  - `git fetch --prune`を実行します。

### log

- `z.git.log`
  - ユーザー情報と整形したコミットログを表示します。

```zsh
z.git.log
# => * <hash> [<date>] <author> <refs>
# =>   <message>
```

### merge

- `z.git.merge`
  - 作業ツリーに変更があれば拒否し、マージ前に`fetch --prune`を実行します。

```zsh
z.git.merge main
```

### mode

- `z.git.mode` / `z.git`
  - Git操作用の対話モードです。

```zsh
z.git.mode
#z.git.> c.g feat "add new feature"
```

### pull

- `z.git.pull`
  - 現在のブランチの状況に応じてpullします。

```zsh
z.git.pull                  # auto-detect
z.git.pull origin develop   # delegate to git pull as-is
z.git.pull dev              # pull from develop branch
```

動作:

- 引数に`origin`が含まれれば、そのまま`git pull`へ渡します。
- 引数に`dev`または`develop`が含まれれば、`git pull origin develop`を実行します。
- 現在のブランチが`pr/<number>`なら、PRのheadブランチを解決して`git pull origin <head-branch>`を実行します。
- それ以外は`git pull origin <current_branch>`を実行します。

### push

- `z.git.push`
  - 現在のブランチの状況に応じてpushします。

```zsh
z.git.push                  # auto-detect
z.git.push origin develop   # delegate to git push as-is
```

動作:

- 引数に`origin`が含まれれば、そのまま`git push`へ渡します。
- 現在のブランチが`pr/<number>`なら、PRのheadブランチを解決して`git push --set-upstream origin HEAD:<head-branch>`を実行します。
- それ以外は`git push --set-upstream origin <current_branch>`を実行します。

### stats

- `z.git.stats`
  - 作成者ごとのコミット統計を表形式で表示します。

```zsh
z.git.stats
z.git.stats exclude_exts="md txt" exclude_dirs="docs tests"
```

- `exclude_exts`: 除外する拡張子（既定: `log`、`lock`）
- `exclude_dirs`: 除外するディレクトリ（既定: `node_modules`、`dist`）

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
  - upstreamとの差分も含め、`git status --short`を表示します。

```zsh
z.git.status
# => 'origin/main' by 2 commits.
# => M modified_file.txt
```

### user

- `z.git.user`
  - Gitのローカルとグローバルのユーザー情報を表示します。
- `z.git.user.local`
  - Gitのローカルのユーザー情報を表示します。
- `z.git.user.global`
  - Gitのグローバルのユーザー情報を表示します。

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
  - Gitのローカルのユーザー情報を設定します。
- `z.git.user.set.global`
  - Gitのグローバルのユーザー情報を設定します。

どちらも`user.name`と`user.email`を引数に指定します。

```zsh
z.git.user.set "milkeclair" "milkeclair@example.com"
z.git.user.set.global "milkeclair" "milkeclair@example.com"
```

- `z.git.user.set.from.global`
  - グローバルな`user.name`と`user.email`を現在のリポジトリのローカル設定へコピーします。

```zsh
z.git.user.set.from.global
```

グローバルな両方の値が設定済みで、空でない必要があります。どちらかがなければ、既存のローカルのユーザー情報を保持します。グローバルの値と無関係なローカル設定は変更せず、設定の書き込みに失敗した場合は0以外の終了コードを返します。

### wt

- `z.git.wt.current.root`
  - 現在のGit worktreeのルートを返します。

```zsh
z.git.wt.current.root
echo $REPLY  #=> "/path/to/worktree"
```

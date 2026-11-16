# z.job

関数をバックグラウンドジョブで実行し、後から結果を回収するmodです。

## インストール

`z.install.mod job`

## 概要

`z.job`は子プロセスで関数を実行します。子プロセスがジョブディレクトリへ状態・終了コード・標準出力・標準エラー・結果ファイルを書き込み、親シェルが完了したジョブを回収してコールバックを実行します。

非同期で実行でき、処理終了後に親シェルが結果を受け取ればよい関数に使います。

## 処理の流れ

1. ジョブのコマンド関数を定義します。
2. 必要に応じて成功時・失敗時のコールバック関数を定義します。
3. `z.job.run`でジョブを開始します。
4. `precmd`から`z.job.collect`を実行するか、手動で呼び出します。

```zsh
my.cache.build() {
  z.arg.named result "$@" && local result=$REPLY

  echo "cache content" > "$result"
}

my.cache.load() {
  z.arg.named result "$@" && local result=$REPLY

  z.file.read path="$result"
  z.io "loaded: $REPLY"
}

z.job.run name=cache command=my.cache.build on_success=my.cache.load
```

## コマンド

### run

- `z.job.run`
  - バックグラウンドジョブを開始します。
  - `REPLY`にジョブIDを返します。
  - `precmd`へ`z.job.collect`を登録します。

引数:

- `name`
  - ジョブ名
- `command`
  - 子プロセスで実行する関数
- `on_success`
  - ジョブ成功時のコールバック関数
- `on_failure`
  - ジョブ失敗時のコールバック関数

```zsh
z.job.run name=cache command=my.cache.build on_success=my.cache.load
local job_id=$REPLY
```

### collect

- `z.job.collect`
  - 完了したジョブを回収します。
  - コールバックを実行します。
  - 回収済みのジョブディレクトリを削除します。
  - 回収したジョブIDを`REPLY`へ返します。
  - コールバックが1つでも失敗した場合は`1`を返します。

```zsh
z.job.collect
echo $REPLY
```

### list

- `z.job.list`
  - `<id> <name> <status>`形式のタブ区切りの行でジョブを表示します。
  - 同じ行を`REPLY`へ返します。

```zsh
z.job.list
```

### status

- `z.job.status id=<id>`
  - 現在のジョブの状態を表示し、`REPLY`へ返します。

```zsh
z.job.status id="$job_id"
```

### is.running

- `z.job.is.running id=<id>`
  - ジョブの状態が`running`で記録されたプロセスが生存していれば、trueを返します。

```zsh
if z.job.is.running id="$job_id"; then
  z.io "running"
fi
```

### cancel

- `z.job.cancel id=<id>`
  - PIDがあれば子プロセスを終了します。
  - ジョブディレクトリを削除します。

```zsh
z.job.cancel id="$job_id"
```

## ジョブのコマンド

コマンド関数は子プロセスで動作し、次の名前付き引数を受け取ります。

- `id`
  - ジョブID
- `name`
  - ジョブ名
- `dir`
  - ジョブディレクトリ
- `result`
  - コマンドの出力を保存するファイルのパス

```zsh
my.job.command() {
  z.arg.named result "$@" && local result=$REPLY

  echo "result text" > "$result"
}
```

子プロセスが書き込む状態:

- コマンド呼び出し前: `running`
- 終了コードが`0`: `success`
- 終了コードが0以外: `failure`

子プロセスで`main.zsh`をsourceした後に、コマンドを呼び出せる必要があります。

## コールバック

`z.job.collect`が完了済みのジョブを回収すると、親シェルでコールバックを実行します。

コールバック関数が受け取る名前付き引数:

- `id`
  - ジョブID
- `name`
  - ジョブ名
- `dir`
  - ジョブディレクトリ
- `result`
  - 結果ファイルのパス
- `exit_status`
  - 子のコマンドの終了コード

```zsh
my.job.success() {
  z.arg.named result "$@" && local result=$REPLY
  z.arg.named exit_status "$@" && local exit_status=$REPLY

  z.file.read path="$result"
  z.io "exit=$exit_status result=$REPLY"
}
```

`success`では`on_success`、`failure`では`on_failure`を実行します。コールバックの指定がなくても、ジョブを回収して削除します。

## ライフサイクル

ジョブの状態:

- `queued`
- `running`
- `success`
- `failure`

`z.job.collect`は、`queued`のジョブでは子のPIDが登録されるまで待ち、子が生存しているジョブは回収しません。`queued`または`running`で、記録されたPIDが既に終了していれば`failure`として回収します。失敗にする前に状態を再確認するため、生存確認中に完了した子の成功・失敗の記録は保持します。

## ファイル

ジョブのファイルは次の場所に保存します。

```zsh
/tmp/z/job/$$/jobs/<job-id>
```

ファイル:

- `meta`
  - sourceできるジョブのメタデータ
- `pid`
  - 子プロセスのID
- `status`
  - `queued`・`running`・`success`・`failure`
- `exit`
  - 子のコマンドの終了コード
- `result`
  - コールバック用の出力
- `stdout`
  - 子の標準出力
- `stderr`
  - 子の標準エラー

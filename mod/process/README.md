# z.process

`z.install.mod process`で`process` modを導入します。

```zsh
z.process.list
z.process.list port=3000
z.process.list name=node
z.process.kill pid=12345
z.process.kill port=3000
z.process.kill name=node
```

`z.process.list`はPID・プロセス名・TCP待受ポートをタブ区切りで表示します。指定がなければ全件、`pid=`・`port=`・`name=`のいずれかを1つ指定すると絞り込みます。複数のポートはカンマ区切りとし、`-`はTCP待受が報告されなかったことを表します。取得できるのは現在のユーザーから見えるポートだけです。`REPLY`にはヘッダーを除いた行を返します。

名前は`ps -A -o comm=`と完全一致で照合し、OSの名前長制限も適用されます。ポートの一覧取得とポートによる絞り込みには`lsof`が必要です。ポート指定はTCP待受を対象とし、一覧には選択した各プロセスの報告された全待受ポートを表示します。

`z.process.kill`では対象の指定を1つだけ渡し、一致する全PIDへSIGTERMを送ります。成功は送信できたことを意味し、プロセスの終了を待たず直ちに戻ります。`REPLY`は送信に成功したPIDです。指定不正、該当なし、照会失敗、送信失敗では終了コード1を返します。

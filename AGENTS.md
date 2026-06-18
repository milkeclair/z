# z

zは、シェルスクリプトの開発を支援するツールキットです。
主にZshで使用することを目的としています。

機能としては、以下のようなものがあります。

- lib
  - libディレクトリは、zのコアライブラリです。
    ここには、シェルスクリプトの開発に役立つ様々なユーティリティ関数が含まれています。
- mod
  - modディレクトリには、zの機能を使ったモディファイアが含まれています。
    これらのモディファイアは、例えばgit操作など、特定のタスクに特化した機能を提供します。
- test
  - testディレクトリには、zの各機能をテストするためのテストスクリプトが含まれています。
    これにより、zの品質と信頼性を確保しています。
    テストはz.tで実行されます。
    worktree内でz.tを実行する場合は、Z_ROOT環境変数を設定する必要があります。
- main.zsh
  - main.zshは、zのエントリーポイントです。
    ここでzの各モジュールやライブラリが読み込まれます。
    zを使用する際には、このファイルをソースすることで、zの機能にアクセスできます。
- zdev
  - zdevファイルは、テストを自動化するためのスクリプトです。
    ファイルが変更されたときに、テストを実行します。

## 関数とディレクトリ構成

zの関数は、関数名の階層とディレクトリ構成を対応させて配置してください。

- `z.a` は `lib/a/process.zsh` または `mod/a/process.zsh` に置きます。
- `z.a.b` は `a` 直下の関数として、`lib/a/analysis.zsh`、`lib/a/process.zsh`、`lib/a/operator.zsh` などに置きます。
- `z.a.b.c` は `b` 直下の関数として、`lib/a/b/analysis.zsh`、`lib/a/b/process.zsh`、`lib/a/b/operator.zsh` などに置きます。
- `z.a.b.c.d` は `c` 直下の関数として、`lib/a/b/c/analysis.zsh`、`lib/a/b/c/process.zsh`、`lib/a/b/c/operator.zsh` などに置きます。

つまり、最後の1 segmentは関数名であり、直前までがディレクトリ階層です。

例:

- `z.mod.depends` は `z.mod` 直下の関数なので、`lib/mod/process.zsh` に置きます。
- `z.mod.dependencies` は `z.mod` 直下の関数なので、`lib/mod/analysis.zsh` に置きます。
- `z.mod.dependencies.resolve` は `dependencies` 直下の関数なので、`lib/mod/dependencies/process.zsh` に置きます。
- `z.mod.is.registered` は `is` 直下の判定関数なので、`lib/mod/is/operator.zsh` に置きます。

`analysis.zsh`、`process.zsh`、`operator.zsh` は関数の性質で選んでください。

- 値を取得・解析して返す関数は `analysis.zsh`
- 状態や変数を更新する関数、処理を実行する関数は `process.zsh`
- 真偽を返す判定関数は `operator.zsh`

テストは実装と同じ階層に置いてください。

- `lib/a/process.zsh` のテストは `test/lib/a/process_test.zsh`
- `lib/a/b/process.zsh` のテストは `test/lib/a/b/process_test.zsh`
- `mod/a/b/operator.zsh` のテストは `test/mod/a/b/operator_test.zsh`

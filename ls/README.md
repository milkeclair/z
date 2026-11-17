# z-ls

## サーバーのメモリ動作

VS Codeのクライアントは、通常起動とデバッグ起動の両方でサーバーに`--no-allocation-site-pretenuring`を指定します。初回の索引作成と繰り返し編集ではトークンの確保位置を共有するため、短命な編集データを直接old領域へ割り当てることを防ぎます。youngからoldへの通常の昇格は有効なままで、フラグの適用先はLanguage Serverのプロセスだけです。

このディレクトリから単体でサーバーを起動する場合も、同じオプションを使います。

```sh
node --no-allocation-site-pretenuring server/dist/server.js --stdio
```

## コード引数の編集

関数コメントで`[code]`と指定した引数には、文字列の内側でも関数補完・補完説明・hover・署名ヘルプ・定義ジャンプが使えます。関数名が`z.*`かどうかに関係なく、コメントの引数指定から判断します。

```zsh
# $1 [code | 'noop']: 実行するZshコード
run_code() {
  if [[ $1 != noop ]]; then
    eval "$1"
  fi
}

# $1: 表示するメッセージ
say() {
  print -r -- "$1"
}

run_code 'say "hello $USER"'
```

`run_code`の文字列内で`say`を補完したり、定義へ移動したりできます。引用符を閉じる前の入力、空文字、複数行、入れ子のコード引数も扱います。補完による置換は元の文書位置へ戻し、外側の引用方式に合わせてエスケープします。

`[code | 'noop']`のような許可値は、通常の文字列として扱います。型と許可値は、関数・引数のhover、署名、補完説明にも表示します。外側の変数展開によって値全体が決まる引数は、コード文字列として確定できるまで通常の引数として扱います。

コード引数内の関数・変数・キーワード・文字列などは、semantic tokensで色分けします。色はVS Codeのテーマに従います。拡張機能は`shellscript`のsemantic highlightingと文字列内の自動補完を既定で有効にし、VS Codeの言語別設定から変更できます。型指定のない文字列には、この拡張機能からコード補完やsemantic tokensを返しません。

編集支援のために文字列のコードを実行することはありません。解析は文書更新時に共有し、コード引数の再解析を32段・ファイルごとの表記を合計1,048,576 UTF-16単位までに制限します。色分けにも走査量と範囲数の上限を設け、深い式で要求処理が膨張することを防ぎます。

## 開発時の検証

Node.js 24を使い、PATHからZshを起動できるようにします。このディレクトリで次を実行します。

```sh
npm ci
npm test -- --maxWorkers=2
```

テストコマンドはPrettierで書式を確認し、ビルド成果物を削除して、clientとserverをコンパイルしてテストの型を確認し、Vitestの全テストを実行します。結合テストではビルドしたNodeサーバーと実際のZshプロセスを起動し、並行実行は2ワーカーに制限します。

リポジトリのCIでも、Zshライブラリのテストと同じソースビルド版のZshを使って検証します。Nodeのセットアップでは`package-lock.json`をキーにnpmのダウンロードをキャッシュし、毎回`npm ci`で固定済みの依存関係を導入します。

## 依存関係の変更

`package.json`を変更する場合は`package-lock.json`もコミットします。依存関係を意図して変更するときは`npm install`でlockfileを更新し、クリーンな導入状態で前述の検証を実行します。

## 拡張機能のパッケージ化

このディレクトリで`npm run package`を実行します。`npm ci`で固定済みの依存関係を導入し、prepublishのビルド後にVSIXを作成します。

## 実装の構成

Lexer、Parser、AST、文書索引、診断は、入力から次の値を返す関数で構成します。レコードと配列はreadonlyで受け渡し、蓄積やキャッシュにはImmutable.jsのList・Map・Setを使います。更新後も元の値を参照でき、既存の値を変更しません。公開するASTやLSPの結果は、境界で通常の配列やMapへ変換します。

走査は配列のmap・reduce、Immutable.jsのRange、またはutil/loop.tsのloop・again・doneで記述します。loopはfp-tsのtailRecを使い、深い入力でも呼び出しスタックを増やさず次の状態へ進みます。let、class、anyによる実装は使いません。

プロセス、接続、タイマーなどのI/Oはclientとserver、および環境取得・ファイル読込の境界に集めます。イベント間で保持する値はutil/ioState.tsで参照し直し、値の変換は独立した関数に渡します。解析用の状態をこの参照へ持ち込まず、更新前後の値を引数と戻り値で表します。

server.tsは接続を組み立て、server/state.tsが保持する値、server/analysis.tsが解析の予約と反映、server/lifecycle.tsが初期化・設定・文書イベントを扱います。server/providers.tsはLSPの要求を各機能へ渡します。ASTの走査はzshParser/ast/traversal、構文の読み取りはzshParser/parser/command、コメントの解析と索引作成はzshHydrator、色分けの範囲収集・重複解消・出力変換はconnection/semanticTokensに分けています。

テストは対象関数、条件、期待する動作の順に記述します。Vitestでは条件を入れ子のdescribeで表し、各testを固定の宣言で記述します。入力の準備、対象関数の実行、結果の検証を区切ります。リポジトリ全体の構文検証は、一つの固定テスト内で各ファイルを照合します。\n\nテストは構文や機能ごとに配置します。server/test/serverは実サーバーの起動、診断、編集反映、再走査、埋め込みコードのシナリオを分け、client.tsにプロセスと通信の操作をまとめています。一時ディレクトリはsupport/tempDirectories.tsで登録し、各テストの終了時に削除します。

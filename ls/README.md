# z-ls

## サーバーのメモリ動作

VS Codeのクライアントは、通常起動とデバッグ起動の両方でサーバーに`--no-allocation-site-pretenuring`を指定します。初回の索引作成と繰り返し編集ではトークンの確保位置を共有するため、短命な編集データを直接old領域へ割り当てることを防ぎます。youngからoldへの通常の昇格は有効なままで、フラグの適用先はLanguage Serverのプロセスだけです。

このディレクトリから単体でサーバーを起動する場合も、同じオプションを使います。

```sh
node --no-allocation-site-pretenuring server/dist/server.js --stdio
```

## 開発時の検証

Node.js 24を使い、PATHからZshを起動できるようにします。このディレクトリで次を実行します。

```sh
npm ci
npm test -- --maxWorkers=2
```

テストコマンドはビルド成果物を削除し、clientとserverをコンパイルしてテストの型を確認し、Vitestの全テストを実行します。結合テストではビルドしたNodeサーバーと実際のZshプロセスを起動し、並行実行は2ワーカーに制限します。

リポジトリのCIでも、Zshライブラリのテストと同じソースビルド版のZshを使って検証します。Nodeのセットアップでは`package-lock.json`をキーにnpmのダウンロードをキャッシュし、毎回`npm ci`で固定済みの依存関係を導入します。

## 依存関係の変更

`package.json`を変更する場合は`package-lock.json`もコミットします。依存関係を意図して変更するときは`npm install`でlockfileを更新し、クリーンな導入状態で前述の検証を実行します。

## 拡張機能のパッケージ化

このディレクトリで`npm run package`を実行します。`npm ci`で固定済みの依存関係を導入し、prepublishのビルド後にVSIXを作成します。

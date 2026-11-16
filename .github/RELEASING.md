# zとz-lsのリリース

## リリースの実行

1. mainのActions → release-draft → Run workflowを開き、2.4.0のような安定版バージョンをvなしで指定します。ソースアーカイブとVSIXのビルド・検証、バージョンコミットとタグのpush、GitHub ReleaseのDraft作成まで実行します。
2. Releasesで用意されたDraftを編集し、複数行のMarkdownを「Release description」へ記入してSave draftを押します。本文は空で作成されるので、リリースノートを自分で記入できます。
3. mainのActions → release-publish → Run workflowを開き、同じバージョンとVisual Studio Marketplaceへ公開するかを指定します。Draftの既存成果物と保存済み本文を取得・検証し、再ビルドせず公開します。本文が空または空白だけなら公開を停止します。

どちらのフォームもバージョン欄は1行です。Markdownは、複数行入力とプレビューに対応したGitHubのリリース編集画面で記入します。リリースノートの自動生成は行いません。編集画面でSave draftを押し、release-publishで最終検証と必要に応じたMarketplace公開を実行します。

公開用ワークフローのファイル名はrelease.ymlのままです。MarketplaceのTrusted Publishingポリシーがこの名前に紐付いているためです。Draft作成用はrelease-draft.ymlです。CLIからは表示名でも実行できます。

```sh
gh workflow run release-draft --ref main -f version=2.4.0
# GitHubで準備済みDraftの本文を編集して保存する。
gh workflow run release-publish --ref main -f version=2.4.0 -F publish_marketplace=false
```

バージョンはz.version、ls/package.json、ls/package-lock.jsonへ適用されます。最初の統一リリースは、既存のz-lsの2.3.0より新しいバージョンにします。以後も両方のバージョンを進めます。現在のワークフローはプレリリースとビルドメタデータには対応していません。

release-draftは入力を検証し、既存のZsh/LSP CIを実行します。読み取り専用のビルドジョブで、ローカルのバージョンコミットと注釈付きvVERSIONタグを作成します。このジョブがVSIXをビルドし、lib・mod・テスト・LSPのソースを含む全追跡対象を梱包します。別のcontents-writeジョブではnpm installやビルドコードを実行せず、信頼済みソースから3つのメタデータ変更を再現し、アーカイブ全体を照合してmainとタグをアトミックにpushします。親が1つであることを検証するためfast-forwardとなり、明示的なleaseによってpushまでmainが実行指定時のSHAを保つことも要求します。

次の成果物をGitHub ReleaseのDraftへ添付し、アップロード後のSHA256を検証して、本文を編集できる状態で終了します。release-publishは公開前に同じバイト列、ソースとバージョンコミット、タグ、保存済みMarkdownを取得して検証します。VSIXのJSONとXMLで拡張機能ID・publisher・バージョン・安定版チャネルが一致し、ソース内容が信頼済みGitツリーに一致する必要があります。ソースtarには検証済みのソース親コミットの時刻と固定権限を使うため、独立して再作成したバージョンコミットからも同じ内容のアーカイブを作れます。

- z-VERSION.tar.gz
- z-ls-VERSION.vsix
- SHA256SUMS

GitHubのimmutable releases設定は有効にしておきます。milkeclair/zでは設定済みです。公開するとタグと成果物のバイト列が固定され、ワークフローも公開後のimmutableフラグを検証します。公開済みの修正は新しいバージョンでリリースします。GitHubではDraftの参照にpush権限が必要なので、Draftを考慮した公開検証は既存のcontents-write公開ジョブで実行します。読み取り専用の事前検証では、実行元ブランチ、固定済みActions、必要に応じたMarketplace設定を確認します。Draft作成・公開ジョブのGITHUB_TOKENにはcontents: writeが必要で、ブランチルールもmainへのバージョンコミットを許可する必要があります。アトミックなpushが拒否されると、mainとタグはどちらも変更されません。

Draft作成ワークフローはローカルのワークフロー参照を使い、同じコミットのCIを再利用します。外部Actionsはactions.lockで固定します。

## Marketplaceへの任意公開

release-publishのチェックボックスの既定値はfalseです。どちらの場合もVSIXはGitHubへ添付します。選択した場合、公開ジョブは公開済みの変更不能な成果物を取得し、チェックサム・バージョン・拡張機能の識別情報を検証してから、次を実行します。

```sh
./node_modules/.bin/vsce publish --oidc --packagePath /path/to/z-ls-VERSION.vsix
```

同じVSIXを再ビルドせず公開します。id-token: writeを要求するのはこのジョブだけです。MarketplaceのPATやリポジトリのsecretは不要です。ジョブはmarketplace Environmentに紐付き、ブランチ制限はワークフローの条件だけに頼らずGitHub側で強制します。

初めてMarketplaceへ公開する前に、次を設定します。

1. リポジトリのSettings → Environmentsでmarketplaceを作成します。デプロイ可能なブランチとタグには、mainブランチだけを許可するルールを1つ設定します。Selected branchesを使い、ワイルドカード・タグのルール・追加のブランチは設定しません。
2. この制限を維持します。事前検証と公開ジョブはactions: readで設定を読み、Environmentがない場合や許可範囲が広い場合は拒否します。
3. publisher「milkeclair」の所有者が、[Marketplaceのpublisher管理画面](https://marketplace.visualstudio.com/manage)で次のTrusted Publishingポリシーを作成します。

| 項目 | 値 |
| --- | --- |
| Policy name | z release workflow |
| Repository owner | milkeclair |
| Repository | z |
| Workflow | release.yml |
| Environment | marketplace |

ワークフローはmainからのリリース実行だけを受け付けます。ポリシーは設定したEnvironmentに紐付けます。Environment欄を空にすると、別ブランチの一致するワークフローファイルも信頼することになるためです。

## 失敗した実行の再開

release-draftの検証・ビルド中にmainが進むとpushが拒否されます。最新の変更を含めるため、現在のmainからrelease-draftを新しく実行します。

バージョンコミットとタグのpush後にDraftの準備が失敗した場合は、同じバージョンでrelease-draftを再実行します。タグがmainに属し、ソース・manifest・lockのバージョンが一致することを確認して、そのタグでCIを実行し、処理を再開します。検証後にタグが変わった場合は新しい実行が必要です。Draft準備の再実行では保存済み本文を保持します。予定した3つの成果物は公開前なら置換できますが、予定外の成果物があれば手動確認のため失敗させます。

release-publishが失敗した場合は、Draftの本文や報告された問題を修正して再実行します。既存のDraftの成果物を取得して公開するため、再ビルド・成果物の置換・mainの更新は行いません。検証中にDraftの本文が変わると失敗し、次回は新しく保存した本文を使います。古いDraftを公開しても、より新しいリリースのLatest指定を保持します。

GitHub Releaseが変更不能になった後も、同じバージョンでrelease-publishを実行すると既存成果物を検証して再利用できます。Marketplaceのチェックボックスを選ぶと、公開を再試行するか、当初GitHubだけで公開した版をMarketplaceにも公開できます。既存の本文・タグ・成果物を保持するため、再試行時のリリースノート入力は不要です。Marketplaceの重複バージョンエラーは黙って成功扱いせず、エラーのまま返します。

GitHubとMarketplaceは別のサービスです。Marketplaceへの公開が失敗しても、変更不能なGitHub Releaseは公開済みのままで、再試行できます。

## バージョンを指定したリリースの導入

GitHub ReleaseからソースアーカイブとSHA256SUMSを取得し、SHA256を検証して展開します。main.zshをsourceする前に、展開したz-VERSIONディレクトリをZ_ROOTへ指定します。modのソースも同じアーカイブに含まれます。対応するVSIXを手動で導入するか、Marketplaceでバージョンを選びます。

既存のz.installは引き続きmainブランチを導入します。特定バージョンの固定された内容が必要な場合は、リリース成果物を使います。

## ローカルでの検証

```sh
node --test .github/scripts/release.test.mjs
cd ls
npm ci
npm test -- --maxWorkers=2
```

成果物の検証では通常ファイル3つだけを受け付けます。ソースの展開後サイズは64 MiB、VSIX本体は128 MiB、VSIXの展開後サイズは512 MiBまで、メタデータは1ファイル1 MiBまでです。ZIP内の重複・安全でないパス、シンボリックリンク、DTD、予定外の識別情報は公開前に拒否します。梱包内容とソースの対応を検証する仕組みであり、レビュー済みのmainのコードと固定済みのビルドツールは信頼する前提です。

リリースのテストは一時的な実Gitリポジトリを使い、バージョン更新・アトミックなpush・参照の競合・成果物検証を確認します。GitHub APIの状態はテストデータを使い、GitHub ReleaseやMarketplace拡張機能を実際には公開しません。

参照:
[GitHubの変更不能なリリース](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)、
[Marketplace Trusted Publishing](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#publish-with-github-actions-and-trusted-publishing)。

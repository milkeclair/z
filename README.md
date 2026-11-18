# z

シェルスクリプトの構文を覚えられない自分のためのZshユーティリティライブラリです。直感的に書きにくい構文を、読みやすい名前の関数で扱えるようにします。

## インストール

### 初回導入

`curl -sL https://raw.githubusercontent.com/milkeclair/z/main/install.zsh | zsh`

### 更新

`z.update`は、読み込み済みのインストール先と導入済みmodを、1つのブランチアーカイブから更新します。必要な依存modも含めます。確認は1回だけ行い、新しいファイルを準備してから置換し、現在のシェルで読み込み直します。Gitの作業ツリーはGitで更新します。

### coreの再インストール

`z.install`は導入済みmodを保持してcoreを置換します。単一のmodを更新するには`z.install.mod <mod_name>`を使います。

`z.install.mod.list`は、配布されているmodと導入済みmodを一覧します。緑は導入済み、オレンジは内容が異なるもの、赤は未導入です。`Z_INSTALL_BRANCH`（既定: `main`）と比較し、ローカルの編集もオレンジで表示します。

`z.install.mod.all`は、1回の確認後に配布対象の全modを導入または更新します。ローカルだけのmodと`mod`直下のファイルは保持し、配布対象のmodを選択したブランチの内容で置換して読み込み直します。

### アンインストール

`z.uninstall`

### バージョン

- `z.version`
  - 現在のバージョンを表示します。
- `z.version.latest`
  - GitHubから最新バージョンを取得して表示します。
- `z.version.note`
  - 現在のバージョンのリリースノートを表示します。
- `z.version.latest.note`
  - GitHubから最新バージョンのリリースノートを取得して表示します。

## 使い方

### ヘルプ

`z.help`でこのREADMEを表示します。

`z.help <function_name>`で関数のドキュメントを表示します。ドキュメントのコメントが見つからない場合は`Document not found`と表示します。

### 使用例

引数の数が2を超えているか確認するスクリプトです。

```zsh
my.argument_check() {
  z.arg.named max $@ default=2 && local max=$REPLY
  z.arg.named.shift max $@
  z.arr.count $REPLY

  if z.int.is.gt $REPLY $max; then
    z.io "more than $max args"
  else
    z.io.error "$max or less args"
  fi
}
```

テスト
```zsh
z.t.describe "my.argument_check"; {
  z.t.context "when more than max args"; {
    z.t.it "prints 'more than max args'"; {
      z.t.mock.call_original name="z.io"

      z.io.null my.argument_check max=3 "1" "2" "3" "4"

      z.t.mock.result
      z.t.expect.reply.includes "more than 3 args"
    }
  }

  z.t.context "when 2 or less args"; {
    z.t.it "prints '2 or less args' to stderr"; {
      z.t.mock name="z.int.is.gt" behavior="return 1"
      z.t.mock name="z.io"
      z.t.mock name="z.io.error"

      z.io.null my.argument_check "1" "2" "3"

      z.t.mock.result name="z.io"
      z.t.expect.reply.is.null skip_unmock=true

      z.t.mock.result name="z.io.error"
      z.t.expect.reply.includes "2 or less args"
    }
  }
}
```

### ライブラリ

よく使う処理を行うユーティリティ関数を提供します。

関数は`z.`、モジュールは`z.<module>.`の接頭辞で名前空間を分けます。

lib配下では次の規則を使います。

- analysis
  - データを変更せずに解析します。
  - 値を返す場合は`return`ではなく`REPLY`へ格納します。
- operator
  - 引数を判定し、trueまたはfalseを`return`します。
  - 判定結果は`REPLY`ではなく、関数の終了コードで返します。
  - if文の条件として使用できます。
- process
  - データを変更します。
  - 値を返す場合は`return`ではなく`REPLY`へ格納します。

返す値は`REPLY`へ直接代入します。文字列を変換せず、配列の要素と空文字列もそのまま保持します。

### モジュール

- arg
  - 名前付き引数と位置引数の解析
- arr
  - join、split、uniqueなど
- common
  - eq、is.null、guardなど
- cls
  - sourceで読み込めるクラス定義、スコープに従う実体参照、メソッドと属性。[クラス](lib/cls/README.md)を参照。
- debug
  - 対話形式のデバッグ
- dir
  - make、remove、existsなど
- file
  - read、write、make.with_dirなど
- fn
  - list、show、editなど
- hash
  - keys、values、mergeなど
- int
  - is.gteq、is.lteq、is.eqなど
- io
  - is.empty、oneline、indentなど
- mode
  - 対話モード
- path
  - dir、base、stemなど
- perm
  - chmod、chown、chgrpのラッパー
- status
  - 終了コードの扱いをまとめた関数
- str
  - color、is.path_like、gsubなど
- t
  - テストフレームワーク
- var
  - exists、sets、getなど

### テスト

テストを記述・実行するフレームワークを提供します。テストはZshで書き、RSpecに似た構文を使います。

全テストを実行するには`z.t`を使います。次のオプションを指定できます。

`z.t`は現在のディレクトリからテストを探します。パスが`/test`で終わるディレクトリで実行してください。それ以外のディレクトリではエラーを返します。

`z_main`には、テスト対象の`main.zsh`のパスが入ります。各テストはこのファイルをsourceして、テスト環境を読み込みます。

- `-l, --log`
  - テストの詳細を表示します。
- `-f, --failed`
  - 失敗したテストだけを表示します。
- `-c, --compact`
  - 結果をドットで簡潔に表示します（`.`: 成功、`F`: 失敗、`*`: 保留）。
- `<name|path>`
  - 一致するテストだけを実行します。
  - ディレクトリ（例: `z.t mod`）なら配下のテストを再帰的に集めます。
  - テストファイルのパス（例: `z.t arg/process`）ならそのファイルだけを実行します。

テストは`test`ディレクトリに置きます。関数は`z.t.`、モジュールは`z.t.<module>.`の接頭辞で名前空間を分けます。

test配下では次の規則を使います。

- describe
  - テストする関数や機能を記述します。
- xdescribe
  - describeブロックをスキップします。
- context
  - テストを実行する条件を記述します。
- xcontext
  - contextブロックをスキップします。
- it
  - 関数や機能に期待する動作を記述します。
- xit
  - itブロックをスキップします。
- expect
  - 関数や機能の期待する動作を検証します。
  - 検証関数は`z.t.expect.`の接頭辞で名前空間を分けます。
- mock
  - 関数やコマンドをモックします。
  - テストや検証の後にモックを自動で解除します。
  - 検証時の解除を省略するには`skip_unmock`を指定します。
  - モックの結果は`return`ではなく`REPLY`へ格納します。
  - モード:
    - 既定: 元の処理を実行せずに呼び出しを記録します。
    - `call_original`: 呼び出しを記録して元の関数を実行します。
      - `z.t.mock.call_original`も同じ動作です。
    - 任意の処理: `behavior`引数にコマンドを渡して処理を指定できます。

## デバッグ

対話形式でデバッグする関数を提供します。

### デバッグ関数の使い方

スクリプト内で`z.debug`を呼ぶとデバッグモードに入ります。実行を一時停止し、対話プロンプトを表示します。

デバッグモードを有効にするには`z.debug.enable`、無効にするには`z.debug.disable`を使います。

デバッグモードで使えるコマンド:

- `c`または`continue`: 実行を続けます。
- `p <var>`または`print <var>`: 変数の値を表示します。
- `h`または`help`: ヘルプを表示します。
- `q`、`quit`、`exit`: スクリプトを終了します。

```zsh
my.function() {
  local var="hello"
  z.debug
  z.io $var
}
```

## 対話モード

関数の実行に接頭辞を付ける対話モードを提供します。デバッグに似ていますが、Git操作のように毎回gitと入力する手間を省くために使います。

```zsh
$ z.mode git
git> status
git> add file.txt
git> commit -m "Add file.txt"
git> push origin branch
git> q
$
```

```zsh
$ z.mode z.io split="."
z.io> oneline "This.is.a.test"
z.io> line "Indented" "line" indent=2
z.io> q
$
```

## mod

特定の作業を行うためのmodを提供します。使いたいものを個別に導入します。

### 導入・更新

`z.install.mod <mod_name>`

依存するmodを解決し、先に導入します。

### アンインストール

`z.uninstall.mod <mod_name>`

### mod一覧

- `z.reload`
  - ホームのZsh設定を読み直します。[README](mod/reload/README.md)
- `z.pj`
  - 名前付きのプロジェクトディレクトリとVS Codeの起動。[README](mod/pj/README.md)
- `z.git`
  - Git操作用のmod。[README](mod/git/README.md)
- `z.wtproxy`
  - Docker Composeとworktree用のプロキシmod。[README](mod/wtproxy/README.md)
- `z.job`
  - 簡単なバックグラウンドジョブ。[README](mod/job/README.md)
- `z.completion`
  - シェルでの関数名やドキュメントの補完。[README](mod/completion/README.md)

## Language Server

Language Serverを提供します。

ダウンロード: https://marketplace.visualstudio.com/items?itemName=milkeclair.z-ls

### 機能

- 補完
  - 関数名
- Hover表示
  - 名前
  - 説明
  - 引数
  - 返り値
  - 使用例
- Signature Help
  - 引数の説明
- 定義への移動
- 診断
  - 関数が見つからない場合の候補提示
  - 空行
    - ファイル先頭
    - 空白だけの行
    - 末尾の改行
  - 未使用の関数引数
  - 必須の位置引数の不足
  - 必須の名前付き引数の不足
  - 抑制コメント（`# zls: ignore`）

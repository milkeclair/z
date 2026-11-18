# クラス

クラス定義は通常のZshファイルです。zを読み込んだ後に定義ファイルをsourceします。
メソッド本体は、引用しないシェルコードとして記述できます。

次の定義を`counter.zsh`へ保存します。

```zsh
z.cls.draw Counter
  z.cls.attr count default=0

  z.cls.fn increment
    $self.count.get || return 1
    $self.count.set "$(( REPLY + 1 ))" || return 1
    $self.count.get
  z.cls.fn.done

  z.cls.fn add
    z.arg.named count "$@" && local count=$REPLY
    z.int.is.match "$count" || return 1
    $self.count.get || return 1
    $self.count.set "$(( REPLY + count ))" || return 1
    $self.count.get
  z.cls.fn.done

z.cls.drew
```

実体を作成すると、変数を展開してメソッドや属性の取得・更新を呼び出せます。

```zsh
source ./counter.zsh
typeset counter=""
z.cls.new Counter counter

$counter.increment
$counter.add count=4
$counter.count.get
print -r -- "$REPLY"  # 5

$counter.count.set 10
$counter.increment
print -r -- "$REPLY"  # 11

z.cls.delete counter
```

## メソッドからのアクセス

メソッドには、実体IDを持つreadonlyのローカル変数`self`を渡します。
同じ実体のメソッドは`$self.increment`、属性は`$self.count.get`と
`$self.count.set value`で呼び出します。実体IDには空白やシェルの特殊文字を含めないため、
この形式で呼び出せます。

上の`add`にある`local count`は名前付き引数を受け取る通常のローカル変数です。
同名の属性はgetter/setterから取得・更新するため、呼出元やメソッド内の`count`が
属性を隠したり、属性への代入になったりすることはありません。

setterが成功すると、その時点で保存値へ反映します。直後のgetterや同じ実体の
別メソッドから更新が見え、後でメソッドが`return 7`しても更新を保持します。
別の実体のメソッドを呼ぶ間はその実体の`self`が見え、戻ると元の`self`へ戻ります。

## 参照と変数のスコープ

`z.cls.new Class variable`は、指定した変数と`REPLY`へ実体参照を代入し、
指定した変数をreadonlyにし、実体の唯一の所有変数として登録します。変数は呼出元で先に宣言します。
同じ変数への再代入や、同じ変数を使った実体の再生成は拒否されます。

以下の例は、それぞれの前の実行例とは独立したシェルで、Counterの定義を
読み込んだ状態から実行します。ローカルな参照を作る場合は、呼出元で変数をlocal宣言します。

```zsh
typeset counter=""
z.cls.new Counter counter
$counter.count.set 10

example() {
  local counter=""
  z.cls.new Counter counter
  $counter.increment
  print -r -- "$REPLY"  # 1
  z.cls.delete counter
}

example
$counter.count.get
print -r -- "$REPLY"  # 10
```

続けて参照をコピーすると、同じ実体の状態を共有できます。コピーは借用参照で、実体の寿命を延ばしません。
参照を展開したコマンド名は、その参照を持つ変数からメソッドや属性を呼び出します。

```zsh
typeset -r other=$counter
"$other.increment"
"$other.count.get"
print -r -- "$REPLY"  # 11
```

`$counter.increment`と`$other.increment`は、それぞれの変数に保存した実体参照を展開して呼び出します。
新しい実体には、内側のスコープで宣言した同名localなど、新しい代入先が必要です。
コピーした参照も再代入から保護する場合は、`typeset -r`または`local -r`を使います。

`z.cls.delete variable`または`z.cls.delete "$reference"`で実体を解放します。
削除後も参照変数の値とreadonly属性は残りますが、その実体への参照は全て無効になります。
所有変数のスコープを抜けた実体は、前回の回収から64件生成された後の次のnewで自動回収します。
実行中の実体は、メソッドが終了した後に回収できます。
属性や配列に入れた実体IDも借用参照で、実体の寿命は所有変数に従います。

実体を呼出元に渡す場合は、所有権を宣言済みの変数へ移します。

```zsh
prepare_counter() {
  local counter=""
  z.cls.new Counter counter || return 1
  $counter.count.set 5
  z.cls.owner.move from=counter "to=$1"
}

example() {
  local saved=""
  prepare_counter saved || return 1
  $saved.count.get
  # REPLY: 5
}
```

移動元に残る値は借用参照です。移動先からは実体IDを展開して呼び出します。

## 定義と呼出しの規則

- 同時に定義できるクラスは1つです。クラス名はシェル内で一意にします。
- 名前には英字・数字・アンダースコアを使えます。先頭は英字かアンダースコアです。
  `z_cls_`で始まる名前は内部用に予約しています。
- `z.cls.attr`の初期値は、空文字列を含むスカラーとして保存します。
  getterは保存したスカラー・配列の形式を返し、setterは保存型に沿って更新します。
  型付きの保存値では整数の基数・浮動小数・配列のフラグも保持します。
  添字配列のsetterには要素を、連想配列のsetterには偶数個のキーと値の組を渡します。
- 属性名は通常の変数名にします。Zshの特殊パラメータと`REPLY`・`reply`は予約名です。
- 実体参照の代入先は、書込み可能な通常のスカラー変数にします。
  作成後はreadonlyになりますが、属性は引き続き更新できます。
- `z.cls.fn name`と`z.cls.fn.done`は、独立した無条件の文として記述します。
  本体内の引用、コメント、ヒアドキュメント、パイプ、条件分岐、通常のループはZshの構文です。
- `z.cls.fn name 'body'`で短い本体を引数として登録することもできます。
- クラスの境界は`z.cls.draw`と`z.cls.drew`、メソッド本体の境界は`z.cls.fn`と`z.cls.fn.done`です。字下げは読みやすさのために使います。
- 属性は`z.cls.attr name default=value`で宣言します。`default=0`は文字列`0`、`default=`は空文字列です。`default`の省略や重複した属性は定義エラーになり、`z.cls.drew`で1を返します。
- `z.cls.draw`が定義を拒否すると、対応する`z.cls.drew`までコマンドを読み飛ばします。その`z.cls.drew`は1を返し、定義中だった外側のクラスは続けられます。
- `z.cls.drew`でクラスを公開し、`z.cls.abort`で未完了の定義を破棄します。
  メソッドの終了前に定義元の実行コンテキストを抜けた場合も、未完了の定義を破棄します。
- 引数、標準出力・標準エラー、`REPLY`、終了コードをそのまま渡します。
  0以外の終了コードを含め、明示的なreturnでも属性の更新を保存します。
- 同じ実体への入れ子の呼出しは、同じ実体IDと保存値を共有します。
  別の実体の呼出しを経由して、実行中の実体へ戻る再入は拒否します。
- サブシェルやコマンド置換には、通常のシェルのプロセス分離が適用されます。
  状態の更新を残す必要がある結果には`REPLY`を使います。

## 公開APIと内部関数

公開APIはdraw、attr、fn、fn.done、drew、abort、new、owner.move、deleteの9関数です。
内部の補助関数は、zの既存規約に従い、関数名の最後の区切りをアンダースコアから始めます。
シェル補完とz-lsは通常、この補助関数を候補から除外します。
z-lsではshowPrivateFunctions設定で表示できます。この規約は、Zshからの直接呼出しを制限するものではありません。

整数、型フラグ、名前、登録状態の検証にはzの共通APIを使います。
共有getterは文字列の要素を保持します。クラスのgetterはさらにスカラーと配列の結果形式を保ち、
実体IDに対応した保存値を取得します。メソッド内のローカル変数は属性の保存領域として使いません。

## 実行時の処理と編集

メソッド本体の収集では、ZshのDEBUGトラップを一時的に使い、
コマンドを実行せずに記録します。終了マーカーで、元の関数形式またはリスト形式の
DEBUGトラップと、実行タイミング・localtrapsの設定を復元します。
収集中は元のDEBUGトラップを一時停止します。Zshがコードを復元するため、
実行時に保存する本体には元のコメントや整形を保持しません。

定義ファイルは通常のシェル構文を保つため、シンタックスハイライトと本体の診断を利用できます。

## 実行時の費用

メソッド呼出しでは実体IDを`self`へ渡し、属性の変数を復元せずに本体を実行します。
通常のスカラー属性の取得・更新は、その属性の保存値だけを扱います。
型付きの値を扱う場合はアクセサー内で必要な属性を復元し、更新に成功すると宣言へ保存します。
数値式を評価するsetterでは、同じ実体の他の属性も参照できます。

メソッドと属性のコマンドは、短い呼出し本体を処理とメンバーごとにキャッシュし、
`functions -c`でコンパイル済みの本体を共有します。実体のコマンドごとに本体を保存・コンパイルする費用を抑えます。
削除前には登録した本体との一致を確認し、利用者が置き換えた関数を保護します。

関数名の登録と実体の状態は、実体数・属性数に応じて増えます。
型付きのアクセサーで復元する費用は、対象の属性数と値の大きさに応じて増えます。
実体の削除で、状態、生成したコマンド、実行状態の管理要素を解放します。

最後の実体を削除した後は、実体用の空テーブルを作り直し、
容量と未設定の検索ノードを解放します。クラス定義と共有する呼出し本体は、
そのシェルのセッション内でキャッシュを保持します。

解放したメモリを同じZshプロセスで再利用するためにアロケータが保持すると、
RSSは起動時の値まで戻らないことがあります。プロセスの終了時には全メモリを解放します。
クリーンアップは通常のZshだけで動作し、ネイティブモジュールは必要ありません。

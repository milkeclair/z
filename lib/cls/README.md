# クラス

クラス定義は通常のZshファイルです。zを読み込んだ後に定義ファイルをsourceします。
メソッド本体は、引用しないシェルコードとして記述できます。

次の定義を`counter.zsh`へ保存します。

```zsh
z.cls.draw Counter
  z.cls.attr count default=0

  z.cls.method increment
    $self.count.get || return 1
    $self.count.set "$(( REPLY + 1 ))" || return 1
    $self.count.get
  z.cls.method.defined

  z.cls.method add
    z.arg.named count "$@" && local count=$REPLY
    z.int.is.match "$count" || return 1
    $self.count.get || return 1
    $self.count.set "$(( REPLY + count ))" || return 1
    $self.count.get
  z.cls.method.defined

z.cls.drew
```

インスタンスを作成すると、メソッドと属性の取得・更新用コマンドを呼び出せます。

```zsh
source ./counter.zsh

local counter=""
z.cls.new Counter counter

$counter.increment
$counter.add count=4
$counter.count.get
z.io "$REPLY"  # 5

$counter.count.set 10
$counter.increment
z.io "$REPLY"  # 11

z.cls.delete counter
```

## メソッドからのアクセス

メソッドには、インスタンスIDを持つreadonlyのローカル変数`self`を渡します。
同じインスタンスのメソッドは`$self.increment`、属性は`$self.count.get`と
`$self.count.set value`で呼び出します。インスタンスIDには空白やシェルの特殊文字を含めないため、
この形式で呼び出せます。

上の`add`にある`local count`は名前付き引数を受け取る通常のローカル変数です。
同名の属性はgetter/setterから取得・更新するため、呼び出し元やメソッド内の`count`が
属性を隠したり、属性への代入になったりすることはありません。

setterが成功すると、その時点で保存値へ反映します。直後のgetterや同じインスタンスの
別メソッドから更新が見え、後でメソッドが`return 7`しても更新を保持します。
別のインスタンスのメソッドを呼ぶ間はそのインスタンスの`self`が見え、戻ると元の`self`へ戻ります。

## 参照と変数のスコープ

参照を受け取る変数を宣言してから、`z.cls.new Class variable`を呼びます。
指定した変数と`REPLY`へインスタンス参照を代入し、指定した変数をreadonlyにします。
参照を持つ変数は通常のZshのスコープに従います。
同じ変数への再代入や、同じ変数を使ったインスタンスの再生成は拒否されます。

次の例は、Counterの定義を読み込んだ新しいシェルで実行します。
`example`の中でも同じ変数名を宣言し、別のインスタンスを作ります。

```zsh
local counter=""
z.cls.new Counter counter
$counter.count.set 10

example() {
  local counter=""
  z.cls.new Counter counter
  $counter.increment
  z.io "$REPLY"  # 1
  z.cls.delete counter
}

example
$counter.count.get
z.io "$REPLY"  # 10
```

参照をコピーした変数でも、同じインスタンスのメソッドと属性を呼び出せます。

```zsh
typeset -r other=$counter
$other.increment
$other.count.get
z.io "$REPLY"  # 11
```

`$counter.increment`や`$other.increment`では、変数の値であるインスタンスIDを展開します。
新しいインスタンスには、内側のスコープの同名変数など、新しい代入先を用意します。
コピーした参照も再代入から保護する場合は、`typeset -r`または`local -r`を使います。

`z.cls.delete variable`または`z.cls.delete "$reference"`でインスタンスを解放します。
削除後も参照変数の値とreadonly属性は残りますが、そのインスタンスへの参照は全て無効になります。
変数のスコープを抜けるだけではインスタンスの状態を解放しないため、使い終わったら明示的に削除します。

## 定義と呼び出しの規則

- 同時に定義できるクラスは1つです。クラス名はシェル内で一意にします。
- 名前には英字・数字・アンダースコアを使えます。先頭は英字かアンダースコアです。
  `z_cls_`で始まる名前は内部用に予約しています。
- `z.cls.attr`の初期値は、空文字列を含むスカラーとして保存します。
  getterは保存したスカラー・配列の形式を返し、setterは保存型に沿って更新します。
  型付きの保存値では整数の基数・浮動小数・配列のフラグも保持します。
  添字配列のsetterには要素を、連想配列のsetterには偶数個のキーと値の組を渡します。
- 属性名は通常の変数名にします。Zshの特殊パラメータと`REPLY`・`reply`は予約名です。
- インスタンス参照の代入先は、書込み可能な通常のスカラー変数にします。
  作成後はreadonlyになりますが、属性は引き続き更新できます。
- `z.cls.method name`と`z.cls.method.defined`は、独立した無条件の文として記述します。
  本体内の引用、コメント、ヒアドキュメント、パイプ、条件分岐、通常のループはZshの構文です。
- `z.cls.method name 'body'`で短い本体を引数として登録することもできます。
- クラスの境界は`z.cls.draw`と`z.cls.drew`、メソッド本体の境界は`z.cls.method`と`z.cls.method.defined`です。字下げは読みやすさのために使います。
- 属性は`z.cls.attr name default=value`で宣言します。`default=0`は文字列`0`、`default=`は空文字列です。`default`の省略や重複した属性は定義エラーになり、`z.cls.drew`で1を返します。
- `z.cls.draw`が定義を拒否すると、対応する`z.cls.drew`までコマンドを読み飛ばします。その`z.cls.drew`は1を返し、定義中だった外側のクラスは続けられます。
- `z.cls.drew`でクラスを公開し、`z.cls.abort`で未完了の定義を破棄します。
  メソッドの終了前に定義元の実行コンテキストを抜けた場合も、未完了の定義を破棄します。
- 引数、標準出力・標準エラー、`REPLY`、終了コードをそのまま渡します。
  0以外の終了コードを含め、明示的なreturnでも属性の更新を保存します。
- 同じインスタンスへの入れ子の呼び出しは、同じインスタンスIDと保存値を共有します。
  別のインスタンスの呼び出しを経由して、実行中のインスタンスへ戻る再入は拒否します。
- サブシェルやコマンド置換には、通常のシェルのプロセス分離が適用されます。
  状態の更新を残す必要がある結果には`REPLY`を使います。

## 公開APIと内部関数

公開APIはdraw、attr、method、method.defined、drew、abort、new、deleteの8関数です。
内部の補助関数は、zの既存規約に従い、関数名の最後の区切りをアンダースコアから始めます。
シェル補完とz-lsは通常、この補助関数を候補から除外します。
z-lsではshowPrivateFunctions設定で表示できます。この規約は、Zshからの直接呼び出しを制限するものではありません。

整数、型フラグ、名前、登録状態の検証にはzの共通APIを使います。
共有getterは文字列の要素を保持します。クラスのgetterはさらにスカラーと配列の結果形式を保ち、
インスタンスIDに対応した保存値を取得します。メソッド内のローカル変数は属性の保存領域として使いません。

## 実行時の処理と編集

クラスの定義中は元のDEBUGトラップを退避し、メソッド本体のコマンドを実行せずに記録します。
`z.cls.method.defined`で本体の収集を終え、`z.cls.drew`または`z.cls.abort`で
元のDEBUGトラップと、実行タイミング・`localtraps`の設定を復元します。
保存する本体には、Zshが復元したコマンドを使います。

定義ファイルは通常のシェル構文を保つため、シンタックスハイライトと本体の診断を利用できます。
z-lsは通常のASTへクラス・属性・メソッド・実体の意味情報を付加し、
共有する索引から生成済みコマンドの定義元を解決します。
メソッド本体の診断位置を保持し、引数で渡す本体は共通の[code]解析を利用します。
動的な名前の解決には、既存の保守的な解析を適用します。

## 実行時の費用

メソッド呼び出しではインスタンスIDを`self`へ渡し、属性の変数を復元せずに本体を実行します。
通常のスカラー属性の取得・更新は、その属性の保存値だけを扱います。
型付きの値を扱う場合はアクセサー内で必要な属性を復元し、更新に成功すると宣言へ保存します。
数値式を評価するsetterでは、同じインスタンスの他の属性も参照できます。

メソッドと属性のコマンドは、短い呼び出し本体を処理とメンバーごとにキャッシュし、
`functions -c`でコンパイル済みの本体を共有します。インスタンスのコマンドごとに本体を保存・コンパイルする費用を抑えます。
削除前には登録した本体との一致を確認し、利用者が置き換えた関数を保護します。

関数名の登録とインスタンスの状態は、インスタンス数・属性数に応じて増えます。
型付きのアクセサーで復元する費用は、対象の属性数と値の大きさに応じて増えます。
インスタンスの削除で、状態、生成したコマンド、実行状態の管理要素を解放します。

最後のインスタンスを削除した後は、インスタンス用の空テーブルを作り直し、
容量と未設定の検索ノードを解放します。クラス定義と共有する呼び出し本体は、
そのシェルのセッション内でキャッシュを保持します。

解放したメモリを同じZshプロセスで再利用するためにアロケータが保持すると、
RSSは起動時の値まで戻らないことがあります。プロセスの終了時には全メモリを解放します。
クリーンアップは通常のZshだけで動作し、ネイティブモジュールは必要ありません。

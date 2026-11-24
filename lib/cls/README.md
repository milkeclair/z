# クラス

クラス定義は通常のZshファイルです。zを読み込んだ後に定義ファイルをsourceします。
メソッド本体は、引用しないシェルコードとして記述できます。

次の定義を`counter.zsh`へ保存します。

```zsh
z.cls.draw Counter
  z.cls.attr count default=0

  # $self [Counter<write>]: 更新するインスタンス
  z.cls.method increment
    $self.count.get || return
    $self.count.set "$(( REPLY + 1 ))" || return
    $self.count.get
  z.cls.method.defined

  # $self [Counter<write>]: 更新するインスタンス
  z.cls.method add
    z.arg.named count "$@" && local count=$REPLY
    z.int.is.match "$count" || return
    $self.count.get || return
    $self.count.set "$(( REPLY + count ))" || return
    $self.count.get
  z.cls.method.defined
z.cls.drew
```

インスタンスを作成すると、変数を展開してメソッドや属性の取得・更新を呼び出せます。

```zsh
source ./counter.zsh
typeset counter=""
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

メソッドには、呼び出しに使ったインスタンス参照をreadonlyのローカル変数 `self` で渡します。
同じインスタンスのメソッドは `$self.increment` で呼び出します。
属性には `$self.count.get` と `$self.count.set value` でアクセスします。

上の`add`にある`local count`は名前付き引数を受け取る通常のローカル変数です。
同名の属性はgetter/setterから取得・更新するため、呼出元やメソッド内の`count`が
属性を隠したり、属性への代入になったりすることはありません。

setterが成功すると、その時点で保存値へ反映します。直後のgetterや同じインスタンスの
別メソッドから更新が見え、後でメソッドが`return 7`しても更新を保持します。
別のインスタンスのメソッドを呼ぶ間はそのインスタンスの`self`が見え、戻ると元の`self`へ戻ります。

## 参照と変数のスコープ

`z.cls.new Class variable`は、指定した変数と`REPLY`へインスタンス参照を代入し、
指定した変数をreadonlyにし、インスタンスの唯一の所有変数として登録します。変数は呼出元で先に宣言します。
同じ変数への再代入や、同じ変数を使ったインスタンスの再生成は拒否されます。

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
  z.io "$REPLY"  # 1
  z.cls.delete counter
}

example
$counter.count.get
z.io "$REPLY"  # 10
```

続けて参照をコピーすると、同じインスタンスの状態を共有できます。コピーは同じ呼び出し用IDを保持します。インスタンスの寿命は所有者に従います。
参照を展開したコマンド名は、その参照を持つ変数からメソッドや属性を呼び出します。

```zsh
typeset -r other=$counter
$other.increment
$other.count.get
z.io "$REPLY"  # 11
```

`$counter.increment`と`$other.increment`は、それぞれの変数に保存したインスタンス参照を展開して呼び出します。
新しいインスタンスには、内側のスコープで宣言した同名localなど、新しい代入先が必要です。
コピーした参照も再代入から保護する場合は、`typeset -r`または`local -r`を使います。

`z.cls.delete variable`または`z.cls.delete "$reference"`でインスタンスを解放します。
削除後も参照変数の値とreadonly属性は残りますが、そのインスタンスへの参照は全て無効になります。
所有変数には、同じスコープで消える配列をマークとして結び付けます。
所有変数のスコープを抜けるとマークが消え、残っている参照からのアクセスはその時点で失敗します。
前回の回収から64個のインスタンスを生成すると、次の `z.cls.new` でマークが消えたインスタンスを回収します。
実行中のインスタンスは、メソッドが終了した後の回収で解放します。

インスタンスを呼出元に渡す場合は、所有権を宣言済みの変数へ移します。

```zsh
source ./counter.zsh

prepare_counter() {
  local counter=""
  z.cls.new Counter counter || return
  $counter.count.set 5 || return
  z.cls.owner.move from=counter "to=$1"
}

use_counter() {
  local saved=""
  prepare_counter saved || return
  $saved.count.get
  # REPLY: 5
}

use_counter
```

所有権を移すと、移動先は同じインスタンスを指す新しい参照を受け取ります。
属性の保存に使うインスタンスIDは保持し、参照とマークを移動先へ付け替えます。
移動前の参照とそのコピーは移動直後に失効します。

## 定義と呼出しの規則

- 同時に定義できるクラスは1つです。クラス名はシェル内で一意にします。
- 名前には英字・数字・アンダースコアを使えます。先頭は英字かアンダースコアです。
  `z_cls_`で始まる名前は内部用に予約しています。
- `z.cls.attr`の初期値とsetterに渡す値は文字列です。空文字列にするには `$counter.count.set ""` と書きます。
  getterは属性の文字列を `REPLY` に返します。
- 属性名は通常の変数名にします。Zshの特殊パラメータと`REPLY`・`reply`は予約名です。
- インスタンス参照の代入先は、書込み可能な通常のスカラー変数にします。
  作成後はreadonlyになりますが、属性は引き続き更新できます。
- `$self` は呼び出しに使ったインスタンス参照です。参照を受け取った関数からも同じインスタンスを更新できます。コメントの `[Counter<read>]` と `[Counter<write>]` はLSPが検査する契約です。
- `z.cls.method`と`z.cls.method.defined`は、独立した無条件の文として記述します。
  本体内の引用、コメント、ヒアドキュメント、パイプ、条件分岐、通常のループはZshの構文です。
- `z.cls.method name 'body'`で短い本体を引数として登録することもできます。
- クラスの境界は`z.cls.draw`と`z.cls.drew`、メソッド本体の境界は`z.cls.method`と`z.cls.method.defined`です。字下げは読みやすさのために使います。
- 属性は`z.cls.attr name default=value`で宣言します。`default=0`は文字列`0`、`default=`は空文字列です。`default`の省略や重複した属性は定義エラーになり、`z.cls.drew`で1を返します。
- `z.cls.draw`が定義を拒否すると、対応する`z.cls.drew`までコマンドを読み飛ばします。その`z.cls.drew`は1を返し、定義中だった外側のクラスは続けられます。
- `z.cls.drew`でクラスを公開し、`z.cls.abort`で未完了の定義を破棄します。
  メソッドの終了前に定義元の実行コンテキストを抜けた場合も、未完了の定義を破棄します。
- 引数、標準出力・標準エラー、`REPLY`、終了コードをそのまま渡します。
  0以外の終了コードを含め、明示的なreturnでも属性の更新を保存します。
- 同じインスタンスへの入れ子の呼出しは、同じインスタンスIDと保存値を共有します。
  別のインスタンスの呼出しを経由して、実行中のインスタンスへ戻る再入は拒否します。
- サブシェルやコマンド置換には、通常のシェルのプロセス分離が適用されます。
  状態の更新を残す必要がある結果には`REPLY`を使います。

## 公開APIと内部関数

公開APIはdraw、attr、method、method.defined、drew、abort、new、owner.move、deleteの9関数です。
内部の補助関数は、zの既存規約に従い、関数名の最後の区切りをアンダースコアから始めます。
シェル補完とz-lsは通常、この補助関数を候補から除外します。
z-lsではshowPrivateFunctions設定で表示できます。この規約は、Zshからの直接呼出しを制限するものではありません。

## 実行時の処理と編集

クラスの定義中は元のDEBUGトラップを退避し、メソッド本体のコマンドを実行せずに記録します。
`z.cls.method.defined`で本体の収集を終え、`z.cls.drew`または`z.cls.abort`で
元のDEBUGトラップと、実行タイミング・`localtraps`の設定を復元します。
保存する本体には、Zshが復元したコマンドを使います。

定義ファイルは通常のシェル構文を保つため、シンタックスハイライトと本体の診断を利用できます。

## 実行時の費用

メソッドには、呼び出しに使った参照を `self` として渡します。初期値はクラスが共有し、
インスタンスにはsetterで変更した属性だけを保存します。移動では参照を更新し、
同じインスタンスIDに紐付いた属性値を引き継ぎます。

クラス公開時に、メソッドと属性のコマンド名の接尾辞を確定します。生成・移動・削除は
同じ一覧を使います。呼び出し用テンプレートは `functions -c` で共有し、削除時は
本体が一致する生成コマンドだけを解除します。

最後のインスタンスを削除した後は、インスタンス用の空テーブルを作り直し、
容量と未設定の検索ノードを解放します。クラス定義と共有する呼出し本体は、
そのシェルのセッション内でキャッシュを保持します。

解放したメモリを同じZshプロセスで再利用するためにアロケータが保持すると、
RSSは起動時の値まで戻らないことがあります。プロセスの終了時には全メモリを解放します。
クリーンアップは通常のZshだけで動作し、ネイティブモジュールは必要ありません。

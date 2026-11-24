# Zsh hydrator

hydratorは、汎用Zsh AST上の関数ドキュメント、クラス宣言、登録済みの制御コメントの名前空間を解釈します。変更時は新しい値を作り、情報を付加したASTを返します。関数エントリと位置検索は、返されたAST内のノードを参照します。元のコメント、ソース範囲、トークンも引き続き参照できます。

## ファイルの解析と情報の付加

```ts
const result = createZshFileHydration({
  sourceFile: '/project/example.zsh',
  file: 'example.zsh',
  content: '# $1: file path\nhelper() { print "$1" }\n',
});

const definition = result.functions[0].definition;
const documentation = documentationOf(definition);
// documentation?.parameters[0]: positionalParameterDoc, position 1, description "file path"
const location = locate(result.query, 3);
```

関数エントリは、表現されたすべての関数名の接頭辞を含み、ソース上の名前の記述を保ちます。シェル構文は汎用Lexer/Parserが扱い、このモジュールはドキュメントの規約とクラスDSLの意味を扱います。

## 付加するドキュメント

```text
FunctionDefinition.leadingDoc
  comments -> original CommentNodes
  hydration: FunctionDocumentation
    description: DocDescription[]
    parameters: (PositionalParameterDoc | NamedParameterDoc | RestParameterDoc)[]
    reply: DocReply | null
    returns: DocReturn | null
    examples: DocExample[]
    diagnostics: HydrationDiagnostic[]
```

関連付けたコメントノードを1回読み、ドル記号、引数名、省略可能の印、コロンを直接解析します。位置引数は位置番号と説明を持ち、名前付き引数と残りの引数はそれぞれ別の型で保持します。使用例の内容とインデントはそのまま残し、例示内の引数に似た記述やdirectiveは使用例に属するものとして扱います。

## コード引数の指定

引数の各値にZshのソースが含まれることを指定できます。

```zsh
# $behavior? [code]: 実行するコマンド
mock() { : }
```

名前付き・位置・残りの引数の説明では、コロンの前に`[code]`を指定できます。残りの引数の場合は各引数へ適用します。文字列の選択肢を併記すると、特別な値を解析対象から除けます。

```zsh
# $behavior? [code | 'call_original']: 実行するコマンド
```

引数ノードは`valueType: 'code'`と、必要に応じて`literalValues`を保持します。選択肢は単一引用符または二重引用符で囲み、引用符とバックスラッシュをエスケープできます。通常の説明文と使用例の意味は変わりません。

## 付加するdirective

```ts
const result = createZshFileHydration({
  sourceFile: '/project/example.zsh',
  file: 'example.zsh',
  content: 'helper() { : } # custom: ignore rule\n',
  options: { directiveNamespaces: ['custom'] },
});
const directives = directivesOf(result.ast.comments[0]);
```

既定で登録される名前空間は`zls`です。実際のコメント内容の先頭に名前空間がある場合だけ認識します。各directiveは名前空間・コマンド・引数・範囲を記録し、未完成のコマンドも後で解析できる形で保持します。後段のLSP解析で動作の妥当性を検証し、診断を抑制したり、引数の説明と使用状況を照合したりします。

## 更新と診断

`createZshHydrator(projectRoot, options)`は、ドットファイルと隠しディレクトリを含む`.zsh`ファイルからプロジェクトのsnapshotを作ります。`.git`と`node_modules`は走査しません。プロジェクトルートが空の場合も、次の更新に使う解釈設定を保持します。

`refreshZshHydrator({ previous, projectRoot, documents, options })`は開いている文書を優先し、バージョンと内容が両方一致すれば文書エントリを再利用します。変更ファイルを再構築し、削除ファイルを取り除き、解釈設定が変われば付加情報を作り直します。走査中に消えたものや通常ファイルでなくなったものはsnapshotへ含めず、それ以外のI/Oエラーは呼び出し元へ返します。

バージョン番号がリセットされて再度開かれた文書も、内容が異なれば解析し直します。比較用のコピーを作らず、既存の変更不能な文字列をfingerprintとして保持します。各snapshotは`ast`、`tokens`、`query`、`functions`、`classes`、Lexer・Parser・hydratorそれぞれの診断を持つファイルエントリを含みます。

`documentationOf`、`directivesOf`、`isHydratedDocBlock`、`isHydratedComment`で、型を保って付加情報へアクセスできます。汎用ASTの探索は明示的な構文辺と関連辺を辿り、付加データはこれらのhydrator APIから参照します。

LSP接続はこのAPIを通して、ドキュメントと制御コメントの情報を付加したASTを共有します。

## 実装の役割

- `hydrator.ts`: 全走査と差分更新の選択、ファイル順とsnapshot再利用。
- `inputs.ts`: 開いた文書の選択とプロジェクト内のパス判定。
- `entry.ts`: ディスク・バッファの読込とfingerprint照合。
- `documentation`と`directive.ts`: ドキュメントと制御コメントの解釈。
- `classes`: クラス宣言の意味情報と、最終ASTを参照するクラス索引。

## クラスの意味情報と索引

`hydrateAst`は、通常の`simpleCommand`に`classDefinition`、`classAttribute`、
`classMethod`、`classInstance`の意味情報を付加します。
コマンドの単語、所属する関数、構文の深さから判定します。
通常の構文種別、範囲、トークン、コメントの参照は保持します。

`classInformationOf(command)`で付加情報を取得できます。
`createZshFileHydration`の`classes`は、クラス・メンバー・インスタンスの宣言の索引です。
名前、属性の初期値、所有スコープは返却AST内のノードを直接参照します。
引数で指定した本体は元のWordを、本体を直接記述した場合はソース範囲と終了マークを保持します。

公開済み・破棄済み・未完了の定義を区別し、診断のコマンド解決には公開済みの定義だけを使います。
動的または不正な名前を推測で確定しません。
関数・メソッドの構文スコープと静的に現れた束縛を記録し、条件分岐後の実行状態や実行順は再現しません。

宣言の認識、インスタンスの束縛、メンバー登録、終了マーク、公開は別々のreadonlyな状態遷移です。
役割別の索引構築は新しいコレクションを返し、既存のファイル索引へ追加しません。
情報の付加後に索引を作り、子ノードが更新された場合も最終ASTを参照します。
hydrateAstを再適用すると、元のASTを変えずに意味情報を作り直し、古いクラスの付加情報を取り除きます。

`classMethodAt`は、宣言を再解釈せず、本体の範囲から引数の所有関係を調べます。
診断はこの共通情報を使い、名前の除外だけでなく、メンバーの宣言を解決先として返します。
クラスの索引は診断の呼び出し解決で使用します。通常の関数の補完・hover・定義ジャンプは、関数索引とコード引数の共通解析結果を使用します。

属性は名前と必須の名前付き引数`default=`で宣言します。`default=`や`default=""`で空の初期値も指定できます。
`z.cls.attr default default=0`のように、`default`という属性名も利用できます。
`ClassAttribute.defaultValue`は名前付き引数全体の元のWordを参照し、
`defaultValueRange`は`default=`と引用を除いた値の物理位置を示します。空値は単語の末尾の長さ0の範囲です。
名前付き初期値の省略、余分な引数、属性の重複などがある定義は、`drew`で公開せず破棄済みとして保持します。

定義中のクラスへの入れ子や、同じ構文スコープで公開済みの名前による`draw`は拒否した範囲として分離します。
拒否した範囲のメンバーと終端を外側へ混ぜず、対応する`drew`の後に外側の収集を続けます。
メソッド本体は同じ深さの独立した`method.defined`まで保持し、本体内の`draw`や`drew`、論理演算・パイプ・非同期実行中の`method.defined`で収集を終了しません。

## メソッド内のself参照

メソッド内の読み取り専用変数`self`は、そのメソッドを呼び出したインスタンスへの参照を持ちます。
`"$self.increment"`、`"$self.count.get"`、`"$self.count.set" 3`は、
付加済みASTの所有メソッドと通常の関数スコープから、そのクラスのメンバー宣言へ解決します。
`self`という属性名も利用でき、`"$self.self.get"`でその値を取得します。

引数で渡す本体も共通のコード解析結果と元の単語の位置から所有関係を調べます。
通常の関数を越える所属や、別の`self`の宣言、変動するメンバー名、メソッド外の`$self`は推測で確定しません。
実行時の本体を書き換えず、通常の構文と元の範囲を保持します。

```zsh
z.cls.draw Counter
  z.cls.attr count default=0
  z.cls.method increment
    $self.count.get || return 1
    $self.count.set "$(( REPLY + 1 ))" || return 1
    $self.count.get
  z.cls.method.defined
z.cls.drew

typeset counter
z.cls.new Counter counter
$counter.increment
# REPLY: 1
```

# Zsh hydrator

hydratorは、汎用Zsh AST上の関数ドキュメントと、登録済みの制御コメントの名前空間を解釈します。変更時は新しい値を作り、情報を付加したASTを返します。関数エントリと位置検索は、返されたAST内のノードを参照します。元のコメント、ソース範囲、トークンも引き続き参照できます。

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

関数エントリは、表現されたすべての関数名の接頭辞を含み、ソース上の名前の記述を保ちます。シェル構文は汎用Lexer/Parserが扱い、このモジュールはドキュメントの規約を扱います。

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

バージョン番号がリセットされて再度開かれた文書も、内容が異なれば解析し直します。比較用のコピーを作らず、既存の変更不能な文字列をfingerprintとして保持します。各snapshotは`ast`、`tokens`、`query`、`functions`、Lexer・Parser・hydratorそれぞれの診断を持つファイルエントリを含みます。

`documentationOf`、`directivesOf`、`isHydratedDocBlock`、`isHydratedComment`で、型を保って付加情報へアクセスできます。汎用ASTの探索は明示的な構文辺と関連辺を辿り、付加データはこれらのhydrator APIから参照します。

LSP接続はこのAPIを通して、ドキュメントと制御コメントの情報を付加したASTを共有します。

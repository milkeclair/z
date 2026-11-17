# 汎用Zsh Parser

Lexer、Parser、ASTのユーティリティは、Language Serverの接続から独立してシェル構文を提供します。ASTはreadonlyなレコードと、表現するノードから導いた識別可能なunion型を使います。

## ソースの解析

```ts
import { Lexer } from './lexer';
import { Parser } from './parser';
import { findAll, createQueryContext, locate } from './ast';

const source = 'if ready; then helper() { print "$1" }; fi\n';
const lexed = Lexer.tokenize(source, { sourceFile: 'example.zsh' });
const parsed = Parser.parse(lexed.tokens, { path: 'example.zsh' });

const functions = findAll(parsed.ast, 'functionDefinition');
const names = functions.flatMap((node) => node.names.map((name) => name.raw));
// names: ['helper']

const query = createQueryContext(parsed.ast);
const location = locate(query, source.indexOf('helper'));
```

LexerとParserの診断は別々に返します。未完成の入力に対しても、部分的なノードと診断を保持します。

## 構文とソース位置

主な階層はFile → List → ListItem → Sublist → Pipeline → Commandです。If・loop・caseコマンドは条件・単語・分岐・本体を公開し、コマンド置換とプロセス置換は解析済みのList本体を公開します。条件と算術式は式の文字列と範囲を入れ物として保持し、ヒアドキュメントは元の本体・終端名・引用のフラグ・終了範囲をリダイレクト上に保持します。

ソース範囲の終端はその位置を含まず、オフセットと列はUTF-16単位です。トークンは解析結果のトークン表に保持し、ParserモジュールのtokenAtOffsetまたはtokensInRangeで取得します。元の文字列と単語のpartsは、ソースの記述を保ちます。

単純コマンドは引数とリダイレクトを保持します。sourceや宣言の分類は追加のsemantic情報であり、そこから構文ノードへの参照を共有する場合があります。

## 探索と変換

- syntaxChildrenとforEachChildは、直接所有する構文上の子ノードを列挙します。
- walkとfindAllは既定でその子ノードを辿ります。
- includeRelatedを指定すると、コメント索引、先行するドキュメントブロック、semantic参照も辿ります。共有オブジェクトを訪問するのは1回です。
- createQueryContextとlocateは、構文上の経路とコメント・ドキュメントの所有関係を区別します。先行コメントは関数の構文範囲より前に存在できます。
- mapAstは変更された経路を新しい値で再構築し、共有参照を保ちます。返されたASTには新しい検索コンテキストを作成してください。

walkのvisitorは、部分木を省略する'skip'、探索を終了する'stop'を返せます。深いASTの探索・変換・位置検索は明示的なフレームを使います。Parserの入れ子には上限があり、部分ASTとprocessing-limit診断を返します。コマンド・引数・パイプラインの横方向の列は反復処理します。

## 実装の配置

- `lexer`: カーソル、区切りの探索、トークンの読み取り。
- `parser/list`・`listItem`・`sublist`・`pipeline`: コマンド列の各段階。
- `parser/command`: 単純コマンド、関数定義、複合コマンド、詳細を保持しない式。
- `parser/word`: 単語の断片、引用、展開。
- `ast/command`・`ast/word`: それぞれのノードの型。
- `ast`直下の`file.ts`・`list.ts`・`listItem.ts`・`sublist.ts`・`pipeline.ts`: コマンド列の型。

AST上の親子関係と実装ディレクトリの深さを分け、コマンドの処理からParserの共通状態やASTの型を短いパスで参照できる構成にしています。利用側は`lexer`・`parser`・`ast`の公開エントリから使います。

# Generic Zsh parser

The lexer, parser and AST utilities provide shell syntax independently of a language-server connection.
The AST uses readonly records and a discriminated node union derived from the represented nodes.

## Parse source

```ts
import { Lexer } from './lexer';
import { Parser } from './parser';
import { findAll, createQueryContext, locate } from './ast';

const source = 'if ready; then helper() { print "$1" }; fi\n';
const lexed = Lexer.tokenize(source, { sourceFile: 'example.zsh' });
const parsed = Parser.parse(lexed.tokens, { path: 'example.zsh' });

const functions = findAll(parsed.ast, 'functionDefinition');
const names = functions.flatMap(node => node.names.map(name => name.raw));
// names: ['helper']

const query = createQueryContext(parsed.ast);
const location = locate(query, source.indexOf('helper'));
```

Lexer diagnostics and parser diagnostics are returned separately.
The parser keeps partial nodes and diagnostics for unfinished input.

## Syntax and source coordinates

The main hierarchy is File -> List -> ListItem -> Sublist -> Pipeline -> Command.
If, loop and case commands expose their conditions, words, branches and bodies.
Command and process substitutions expose parsed list bodies.
Conditions and arithmetic expressions retain expression text and ranges as containers.
Here-documents retain the raw body, delimiter, quoting flags and closing range on their redirect.

All source ranges are end-exclusive and use UTF-16 offsets and columns.
Tokens live in the parse result's token table. Use tokenAtOffset or tokensInRange from the parser module to recover source tokens.
Raw text and word parts preserve source spelling.

Simple commands retain their arguments and redirects.
Source/declaration classification is additional semantic information; references in that information may share syntax nodes.

## Explore and transform

- syntaxChildren and forEachChild enumerate immediate owned syntax children.
- walk and findAll follow those children by default.
- includeRelated also follows the comment index, leading documentation blocks and semantic references. Shared objects are visited once.
- createQueryContext and locate distinguish syntax paths from comment/documentation ownership. A leading comment can precede its function's syntax range.
- mapAst rebuilds changed paths immutably and preserves shared references. Create a new query context for the returned AST.

walk visitors can return 'skip' to omit a subtree or 'stop' to end traversal.
Traversal, mapping and position lookup use explicit frames for deep ASTs.
Parser nesting is bounded and reports a processing-limit diagnostic with a partial AST.
Horizontal command, argument and pipeline sequences are processed iteratively.

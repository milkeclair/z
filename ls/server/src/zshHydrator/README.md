# Zsh hydrator

The hydrator interprets function documentation and registered control-comment namespaces on the generic Zsh AST.
It returns an enriched AST through immutable updates. Function entries and position queries refer to nodes in this returned AST.
Original comment text, source ranges and tokens remain available.

## Parse and hydrate a file

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

Function entries include every represented function-name prefix and retain the name's source spelling.
The generic lexer and parser own shell syntax; this module owns documentation conventions.

## Attached documentation

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

The documentation reader consumes associated comment nodes once. It reads dollar markers, parameter names, optional markers and colons directly.
A positional parameter stores its numeric position and prose description; named and rest parameters have their own variants.
Examples keep their content and indentation. Parameter-looking text and directives inside examples belong to the example.

## Attached directives

```ts
const result = createZshFileHydration({
  sourceFile: '/project/example.zsh',
  file: 'example.zsh',
  content: 'helper() { : } # custom: ignore rule\n',
  options: { directiveNamespaces: ['custom'] },
});
const directives = directivesOf(result.ast.comments[0]);
```

The default registered namespace is `zls`. Recognition requires the namespace at the start of the actual comment payload.
Each directive records its namespace, command, arguments and ranges. Incomplete commands remain representable for later analysis.
A later LSP analysis phase validates directive actions, applies suppression and compares documented parameters with usage.

## Refresh and diagnostics

`createZshHydrator(projectRoot, options)` creates a project snapshot from `.zsh` files, including dot files and hidden directories.
The scan skips `.git` and `node_modules`. An empty project root retains the interpretation options for a later refresh.

`refreshZshHydrator({ previous, projectRoot, documents, options })` prioritizes open document content and reuses open-document entries when both the version and content match,
rebuilds changed files, removes deleted files and regenerates attachments when interpretation options change.
Entries that disappear or stop being regular files during a scan are omitted from the snapshot; other I/O errors propagate to the caller.

A reopened document with a reset version is parsed again when its content differs. The fingerprint holds the existing immutable text value without constructing a comparison copy.
Each snapshot contains file entries with `ast`, `tokens`, `query`, `functions`, and separate lexer, parser and hydration diagnostics.

Use `documentationOf`, `directivesOf`, `isHydratedDocBlock` and `isHydratedComment` for typed access to attachments.
The generic AST walker follows explicit syntax and related edges; attachment data is accessed through these hydrator APIs.

The existing LSP connection continues to use its current implementation. This module provides the AST-based API for a later migration.

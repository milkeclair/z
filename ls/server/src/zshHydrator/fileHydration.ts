import type { FileNode, FunctionDefinitionNode, QueryContext } from '../zshParser/ast';
import { createQueryContext, findAll } from '../zshParser/ast';
import type { LexerDiagnostic, Token } from '../zshParser/lexer';
import { Lexer } from '../zshParser/lexer';
import type { ParserDiagnostic } from '../zshParser/parser';
import { Parser } from '../zshParser/parser';
import type { HydrationOptions } from './directive';
import type { HydrationDiagnostic } from './documentation';
import { documentationOf, hydrateAst } from './hydrate';

export type HydratedFunction = {
  readonly name: string;
  readonly definition: FunctionDefinitionNode;
};

export type ZshFileHydration = {
  readonly sourceFile: string;
  readonly file: string;
  readonly ast: FileNode;
  readonly tokens: readonly Token[];
  readonly functions: readonly HydratedFunction[];
  readonly query: QueryContext;
  readonly lexerDiagnostics: readonly LexerDiagnostic[];
  readonly parserDiagnostics: readonly ParserDiagnostic[];
  readonly hydrationDiagnostics: readonly HydrationDiagnostic[];
};

export function createZshFileHydration({
  sourceFile,
  file,
  content,
  options = {},
}: {
  readonly sourceFile: string;
  readonly file: string;
  readonly content: string;
  readonly options?: HydrationOptions;
}): ZshFileHydration {
  const lexed = Lexer.tokenize(content, { sourceFile });
  const parsed = Parser.parse(lexed.tokens, { sourceFile, path: sourceFile });
  const ast = hydrateAst(parsed.ast, content, options);
  const definitions = findAll(ast, 'functionDefinition');

  return {
    sourceFile,
    file,
    ast,
    tokens: parsed.tokens,
    query: createQueryContext(ast),
    functions: definitions.flatMap((definition) =>
      definition.names.map((word) => ({ name: word.raw, definition })),
    ),
    lexerDiagnostics: lexed.diagnostics,
    parserDiagnostics: parsed.diagnostics,
    hydrationDiagnostics: definitions.flatMap((node) => documentationOf(node)?.diagnostics ?? []),
  };
}

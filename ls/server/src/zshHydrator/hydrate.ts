import type { AstNode, CommentNode, DocBlockNode, FileNode, FunctionDefinitionNode } from '../zshParser/ast';
import { findAll, mapAst } from '../zshParser/ast';
import type { FunctionDocumentation } from './documentation';
import { parseFunctionDocumentation } from './documentation';
import type { ControlComment, HydrationOptions } from './directive';
import { parseDirective } from './directive';

export type HydratedDocBlock = DocBlockNode & { readonly hydration: FunctionDocumentation };
export type HydratedComment = CommentNode & { readonly hydration: ControlComment };

export function isHydratedDocBlock(node: DocBlockNode): node is HydratedDocBlock {
  return 'hydration' in node && typeof node.hydration === 'object' && node.hydration !== null &&
    'kind' in node.hydration && node.hydration.kind === 'functionDocumentation';
}
export function isHydratedComment(node: CommentNode): node is HydratedComment {
  return 'hydration' in node && typeof node.hydration === 'object' && node.hydration !== null &&
    'kind' in node.hydration && node.hydration.kind === 'controlComment';
}
export function documentationOf(node: FunctionDefinitionNode | DocBlockNode): FunctionDocumentation | null {
  const block = node.kind === 'functionDefinition' ? node.leadingDoc : node;
  return block && isHydratedDocBlock(block) ? block.hydration : null;
}
export function directivesOf(node: CommentNode): ControlComment['directives'] {
  return isHydratedComment(node) ? node.hydration.directives : [];
}
/** Return one enriched AST, with immutable updates and shared comment references. */
export function hydrateAst(ast: FileNode, source: string, options: HydrationOptions = {}): FileNode {
  const documents = new Map<number, FunctionDocumentation>();
  const exampleComments = new Set<number>();
  for (const definition of findAll(ast, 'functionDefinition')) {
    if (!definition.leadingDoc) continue;
    const result = parseFunctionDocumentation(definition.leadingDoc, source, options);
    documents.set(definition.leadingDoc.range.start.offset, result.documentation);
    for (const offset of result.exampleComments) exampleComments.add(offset);
  }
  return mapAst(ast, (node: AstNode): AstNode => {
    if (node.kind === 'docBlock') {
      const original = documents.get(node.range.start.offset);
      if (original) {
        const hydrated: HydratedDocBlock = { ...node, hydration: original };
        return hydrated;
      }
    } else if (node.kind === 'comment') {
      const directive = exampleComments.has(node.range.start.offset) ? null : parseDirective(node, options);
      if (directive) {
        const hydrated: HydratedComment = { ...node, hydration: { kind: 'controlComment', directives: [directive] } };
        return hydrated;
      }
      if (isHydratedComment(node)) {
        const { hydration, ...syntax } = node;
        return syntax;
      }
    }
    return node;
  });
}

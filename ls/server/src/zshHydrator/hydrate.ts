import { hydrateClasses } from './classes';
import { lowerBound } from '../util/search';
import type {
  AstNode,
  CommentNode,
  DocBlockNode,
  FileNode,
  FunctionDefinitionNode,
} from '../zshParser/ast';
import { findAll, mapAst } from '../zshParser/ast';
import type { ControlComment, HydrationOptions } from './directive';
import { parseDirective } from './directive';
import { parseFunctionDocumentation, type FunctionDocumentation } from './documentation';

export type HydratedDocBlock = DocBlockNode & {
  readonly hydration: FunctionDocumentation;
};

export type HydratedComment = CommentNode & {
  readonly hydration: ControlComment;
};

export function isHydratedDocBlock(node: DocBlockNode): node is HydratedDocBlock {
  return (
    'hydration' in node &&
    typeof node.hydration === 'object' &&
    node.hydration !== null &&
    'kind' in node.hydration &&
    node.hydration.kind === 'functionDocumentation'
  );
}

export function isHydratedComment(node: CommentNode): node is HydratedComment {
  return (
    'hydration' in node &&
    typeof node.hydration === 'object' &&
    node.hydration !== null &&
    'kind' in node.hydration &&
    node.hydration.kind === 'controlComment'
  );
}

export function documentationOf(
  node: FunctionDefinitionNode | DocBlockNode,
): FunctionDocumentation | null {
  const block = node.kind === 'functionDefinition' ? node.leadingDoc : node;

  return block && isHydratedDocBlock(block) ? block.hydration : null;
}

export function directivesOf(node: CommentNode): ControlComment['directives'] {
  return isHydratedComment(node) ? node.hydration.directives : [];
}

/** 変更時に新しい値を作り、コメントの参照を共有しながら、情報を付加した単一のASTを返す。 */
export function hydrateAst(
  ast: FileNode,
  source: string,
  options: HydrationOptions = {},
  definitions = findAll(ast, 'functionDefinition'),
): FileNode {
  const documentedFunctions = definitions.flatMap((definition) =>
    definition.leadingDoc ? [{ definition, leadingDoc: definition.leadingDoc }] : [],
  );
  const parsed = documentedFunctions.map(({ leadingDoc }) => ({
    offset: leadingDoc.range.start.offset,
    ...parseFunctionDocumentation(leadingDoc, source, options),
  }));
  const documents = new Map(parsed.map(({ offset, documentation }) => [offset, documentation]));
  const exampleComments = new Set(parsed.flatMap(({ exampleComments }) => [...exampleComments]));

  if (
    documents.size === 0 &&
    !ast.comments.some((comment) => isHydratedComment(comment) || parseDirective(comment, options))
  ) {
    return hydrateClasses(ast);
  }

  // 先行コメントの位置ではなく、構文の範囲に含まれる関数定義の位置で絞り込む。
  const offsets = documentedFunctions
    .map(({ definition }) => definition.range.start.offset)
    .toSorted((left, right) => left - right);

  const documentedAst = mapAst(
    ast,
    (node: AstNode): AstNode => {
      if (node.kind === 'docBlock') {
        const original = documents.get(node.range.start.offset);

        if (original) {
          const hydrated: HydratedDocBlock = { ...node, hydration: original };

          return hydrated;
        }
      } else if (node.kind === 'comment') {
        const directive = exampleComments.has(node.range.start.offset)
          ? null
          : parseDirective(node, options);

        if (directive) {
          const hydrated: HydratedComment = {
            ...node,
            hydration: { kind: 'controlComment', directives: [directive] },
          };

          return hydrated;
        }

        if (isHydratedComment(node)) {
          const { hydration: _hydration, ...syntax } = node;

          return syntax;
        }
      }

      return node;
    },
    (node) => {
      if (node.kind !== 'listItem') {
        return true;
      }

      const { start, end } = node.range;
      const first = lowerBound(offsets.length, (index) => offsets[index] < start.offset);

      return first < offsets.length && offsets[first] < end.offset;
    },
  );

  return hydrateClasses(documentedAst);
}

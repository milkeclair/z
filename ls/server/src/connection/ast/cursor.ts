import type { CodeProgram } from '../../embeddedCode';
import { codeOffset } from '../../embeddedCode/sourceMap';
import type { FunctionSnapshot } from '../../refreshFunctions/main';
import type { FunctionTargets } from '../../refreshFunctions/target';
import { again, done, loop } from '../../util/loop';
import { lowerBound } from '../../util/search';
import type { TextDocument } from '../../vscode_type';
import type { ZshFileHydration } from '../../zshHydrator';
import type { AstNode, SimpleCommandNode } from '../../zshParser/ast';
import { locate } from '../../zshParser/ast';
import type { SourceRange, Token } from '../../zshParser/lexer';

export type Cursor = {
  readonly file: ZshFileHydration;
  readonly offset: number;
  readonly path: readonly AstNode[];
  readonly token: Token | null;
  readonly program?: CodeProgram;
  readonly targets?: FunctionTargets;
};
type TokenSelection = { readonly selected: number; readonly token: Token | null };
function previousSyntaxToken(
  file: ZshFileHydration,
  content: string,
  offset: number,
): TokenSelection {
  const selected = loop(Math.max(0, offset - 1), (index) =>
    index > 0 && (content[index] === ' ' || content[index] === '\t' || content[index] === '\r')
      ? again(index - 1)
      : done(index),
  );
  return loop<TokenSelection, TokenSelection>(
    { selected, token: tokenAtOffset(file.tokens, selected) },
    (current) => {
      const token = current.token;
      if (!token || (token.kind !== 'whitespace' && token.kind !== 'continuation')) {
        return done(current);
      }
      if (token.range.start.offset === 0) {
        return done({ ...current, token: null });
      }
      const selected = token.range.start.offset - 1;
      return again({ selected, token: tokenAtOffset(file.tokens, selected) });
    },
  );
}
export function cursorAt(
  snapshot: FunctionSnapshot,
  document: TextDocument,
  inputOffset: number,
  programs: readonly CodeProgram[] = [],
): Cursor | null {
  const cached = snapshot.documents.get(document.uri);
  if (!cached || cached.version !== document.version || cached.content !== document.getText()) {
    return null;
  }
  const scoped = programs.reduce<{
    readonly program: CodeProgram | undefined;
    readonly offset: number;
  }>(
    (previous, candidate) => {
      if (
        candidate.root !== cached.file ||
        (previous.program && candidate.depth <= previous.program.depth)
      ) {
        return previous;
      }
      const mapped = codeOffset(candidate.source, inputOffset);
      return mapped === null ? previous : { program: candidate, offset: mapped };
    },
    { program: undefined, offset: inputOffset },
  );
  const { program, offset } = scoped;
  const file = program?.file ?? cached.file,
    content = program?.content ?? cached.content;
  const direct = locate(file.query, offset);
  if (direct?.kind === 'comment') {
    return null;
  }
  const token = tokenAtOffset(file.tokens, offset);
  const previous =
    token?.kind !== 'word' ||
    offset >= token.range.end.offset ||
    (direct?.kind === 'syntax' &&
      (direct.node.kind === 'commandSubstitution' || direct.node.kind === 'processSubstitution'));
  const chosen = previous
    ? previousSyntaxToken(file, content, offset)
    : { selected: offset, token };
  if (
    chosen.token?.kind === 'comment' ||
    chosen.token?.kind === 'hereDocBody' ||
    chosen.token?.kind === 'hereDocEnd'
  ) {
    return null;
  }
  const location = chosen.selected === offset ? direct : locate(file.query, chosen.selected);
  if (location?.kind === 'comment') {
    return null;
  }
  const path = location?.kind === 'syntax' ? location.path : [];
  if (path.some((node) => node.kind === 'opaqueCommand' || node.kind === 'hereDocument')) {
    return null;
  }
  return {
    file,
    offset,
    path,
    token: chosen.token,
    ...(program ? { program } : {}),
    ...(cached.targets ? { targets: cached.targets } : {}),
  };
}
export function callAt(cursor: Cursor): SimpleCommandNode | null {
  for (const node of cursor.path.toReversed()) {
    if (
      node.kind === 'redirect' ||
      node.kind === 'commandSubstitution' ||
      node.kind === 'processSubstitution' ||
      node.kind === 'subshellCommand'
    ) {
      return null;
    }
    if (node.kind === 'simpleCommand') {
      return node;
    }
  }
  return null;
}
export function functionCommand(command: SimpleCommandNode): boolean {
  return !command.precommandModifiers.some(
    (modifier) => modifier.type === 'builtin' || modifier.type === 'command',
  );
}
export function inside(range: SourceRange, offset: number): boolean {
  return range.start.offset <= offset && offset <= range.end.offset;
}
export function protocolRange(range: SourceRange) {
  return {
    start: { line: range.start.line, character: range.start.character },
    end: { line: range.end.line, character: range.end.character },
  };
}
function tokenAtOffset(tokens: readonly Token[], offset: number): Token | null {
  const index = lowerBound(tokens.length, (index) => tokens[index].range.end.offset <= offset);
  const token = tokens[index];
  return token && offset >= token.range.start.offset ? token : null;
}

import type { TextDocument } from '../../vscode_type';
import type { AstNode, SimpleCommandNode } from '../../zshParser/ast';
import { locate } from '../../zshParser/ast';
import type { SourceRange, Token } from '../../zshParser/lexer';
import type { ZshFileHydration } from '../../zshHydrator';
import type { FunctionSnapshot } from '../../refreshFunctions/main';

export type Cursor = {
  readonly file: ZshFileHydration;
  readonly offset: number;
  readonly path: readonly AstNode[];
  readonly token: Token | null;
};

export function cursorAt(snapshot: FunctionSnapshot, document: TextDocument, offset: number): Cursor | null {
  const cached = snapshot.documents.get(document.uri);
  if (!cached || cached.version !== document.version || cached.content !== document.getText()) return null;
  const file = cached.file;
  const content = cached.content;
  const direct = locate(file.query, offset);
  if (direct?.kind === 'comment') return null;
  let token = tokenAtOffset(file.tokens, offset);
  let selected = offset;
  if (token?.kind !== 'word' || offset >= token.range.end.offset || direct?.kind === 'syntax' &&
    (direct.node.kind === 'commandSubstitution' || direct.node.kind === 'processSubstitution')) {
    selected = Math.max(0, offset - 1);
    while (selected > 0 && (content[selected] === ' ' || content[selected] === '\t' || content[selected] === '\r')) selected -= 1;
    token = tokenAtOffset(file.tokens, selected);
    while (token && (token.kind === 'whitespace' || token.kind === 'continuation')) {
      if (token.range.start.offset === 0) { token = null; break; }
      selected = token.range.start.offset - 1;
      token = tokenAtOffset(file.tokens, selected);
    }
  }
  if (token?.kind === 'comment' || token?.kind === 'hereDocBody' || token?.kind === 'hereDocEnd') return null;
  const location = selected === offset ? direct : locate(file.query, selected);
  if (location?.kind === 'comment') return null;
  const path = location?.kind === 'syntax' ? location.path : [];
  if (path.some(node => node.kind === 'opaqueCommand' || node.kind === 'hereDocument')) return null;
  return { file, offset, path, token };
}

export function callAt(cursor: Cursor): SimpleCommandNode | null {
  for (const node of [...cursor.path].reverse()) {
    if (node.kind === 'redirect' || node.kind === 'commandSubstitution' || node.kind === 'processSubstitution' ||
      node.kind === 'subshellCommand') return null;
    if (node.kind === 'simpleCommand') return node;
  }
  return null;
}

export function functionCommand(command: SimpleCommandNode): boolean {
  return !command.precommandModifiers.some(modifier =>
    modifier.type === 'builtin' || modifier.type === 'command' || modifier.type === 'exec');
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
  let low = 0;
  let high = tokens.length - 1;
  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const token = tokens[middle];
    if (offset < token.range.start.offset) high = middle - 1;
    else if (offset >= token.range.end.offset) low = middle + 1;
    else return token;
  }
  return null;
}

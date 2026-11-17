import type { TextDocument } from '../vscode_type';
import type { CodeProgram } from '../embeddedCode';
import type { SourceRange } from '../zshParser/lexer';
import { walk } from '../zshParser/ast';
import { codeRanges, textPosition } from '../embeddedCode/sourceMap';

export const codeTokenTypes = ['function', 'variable', 'parameter', 'keyword', 'string', 'comment', 'number', 'operator'] as const;
type TokenType = typeof codeTokenTypes[number];
type Span = { readonly start: number; readonly end: number; readonly type: TokenType; readonly priority: number };
const MAX_HIGHLIGHT_SPANS = 32768;
const keywords: ReadonlySet<string> = new Set(['if', 'then', 'else', 'elif', 'fi', 'for', 'select', 'foreach', 'repeat',
  'while', 'until', 'do', 'done', 'case', 'in', 'esac', 'function', 'time', 'coproc', 'end']);

/** 内側のASTに従って分類し、物理的に連続する元文書の範囲へ戻す。 */
function programSpans(program: CodeProgram, maxSpans: number): readonly Span[] {
  const result: Span[] = [];
  const words: SourceRange[] = [];
  let remaining = program.content.length * 8;
  const add = (range: SourceRange, type: TokenType, priority: number): void => {
    if (remaining <= 0 || result.length >= maxSpans) return;
    const length = Math.min(range.end.offset - range.start.offset, remaining);
    remaining -= length;
    const bounded = length < range.end.offset - range.start.offset
      ? { ...range, end: textPosition(program.lineStarts, range.start.offset + length) } : range;
    for (const physical of codeRanges(program.source, bounded, maxSpans - result.length)) {
      if (physical.end.offset > physical.start.offset) result.push({
        start: physical.start.offset, end: physical.end.offset, type, priority: program.depth * 100 + priority,
      });
    }
  };
  walk(program.file.ast, node => {
    if (node.kind === 'word') {
      words.push(node.range);
      const number = node.raw.length > 0 && [...node.raw].every(char => char >= '0' && char <= '9');
      add(node.range, node.quoted ? 'string' : number ? 'number' : 'parameter', 10);
    } else if (node.kind === 'commandName') add(node.range, 'function', 30);
    else if (node.kind === 'functionDefinition') {
      for (const name of node.names) add(name.range, 'function', 30);
    } else if (node.kind === 'variableReference' || node.kind === 'parameterExpansion' || node.kind === 'variableName') {
      add(node.range, 'variable', 40);
    } else if (node.kind === 'precommandModifier' || node.kind === 'pipelineModifier' || node.kind === 'pipelineTiming') {
      add(node.range, 'keyword', 20);
    }
    if ('keyword' in node) {
      add(node.keyword, 'keyword', 20);
      if ('close' in node && node.close) add(node.close, 'keyword', 20);
    }
    if ('thenKeyword' in node && node.thenKeyword) add(node.thenKeyword, 'keyword', 20);
  });
  if (remaining <= 0 || result.length >= maxSpans) return result;
  const sortedWords = words.toSorted((a, b) => a.start.offset - b.start.offset);
  let wordIndex = 0; let coveredEnd = -1;
  for (const token of program.file.tokens) {
    while (wordIndex < sortedWords.length && sortedWords[wordIndex].start.offset <= token.range.start.offset) {
      coveredEnd = Math.max(coveredEnd, sortedWords[wordIndex].end.offset); wordIndex++;
    }
    if (token.kind === 'operator') add(token.range, 'operator', 10);
    else if (token.kind === 'comment') add(token.range, 'comment', 50);
    else if (token.kind === 'word' && !token.quoted && keywords.has(token.value) && coveredEnd < token.range.end.offset) {
      add(token.range, 'keyword', 20);
    }
  }
  return result;
}

/** 外側の文字列より深いコードを優先し、重複しない範囲へ整列する。 */
function disjoint(spans: readonly Span[]): readonly Span[] {
  const events = spans.flatMap((span, id) => [
    { offset: span.start, start: true, span, id }, { offset: span.end, start: false, span, id },
  ]).sort((a, b) => a.offset - b.offset);
  const active = new Map<number, Span>();
  const result: Span[] = [];
  let previous = 0; let index = 0;
  while (index < events.length) {
    const offset = events[index].offset;
    let selected: Span | undefined;
    for (const span of active.values()) if (!selected || span.priority > selected.priority) selected = span;
    if (selected && offset > previous) {
      const last = result.at(-1);
      if (last && last.end === previous && last.type === selected.type) {
        result[result.length - 1] = { ...last, end: offset };
      } else result.push({ ...selected, start: previous, end: offset });
    }
    while (index < events.length && events[index].offset === offset) {
      const event = events[index++];
      if (event.start) active.set(event.id, event.span);
      else active.delete(event.id);
    }
    previous = offset;
  }
  return result;
}

/** 解析済みのコード引数だけを色分けし、標準semantic token形式へ変換する。 */
export function zSemanticTokens({ document, programs }: {
  readonly document: TextDocument; readonly programs: readonly CodeProgram[];
}): { readonly data: number[] } {
  const data: number[] = [];
  const content = document.getText();
  let lastLine = 0; let lastCharacter = 0;
  const spans: Span[] = [];
  for (const program of programs) {
    if (spans.length >= MAX_HIGHLIGHT_SPANS) break;
    for (const span of programSpans(program, MAX_HIGHLIGHT_SPANS - spans.length)) spans.push(span);
  }
  for (const span of disjoint(spans)) {
    let offset = span.start;
    while (offset < span.end) {
      const start = document.positionAt(offset);
      const next = document.offsetAt({ line: start.line + 1, character: 0 });
      let end = Math.min(span.end, next);
      while (end > offset && (content[end - 1] === '\n' || content[end - 1] === '\r')) end--;
      if (end > offset) {
        data.push(start.line - lastLine, start.line === lastLine ? start.character - lastCharacter : start.character,
          end - offset, codeTokenTypes.indexOf(span.type), 0);
        lastLine = start.line; lastCharacter = start.character;
        if (data.length >= MAX_HIGHLIGHT_SPANS * 5) return { data };
      }
      if (next <= offset || next >= span.end) break;
      offset = next;
    }
  }
  return { data };
}

import { appendItems, collectArray } from '../../util/collections';
import type { CodeProgram } from '../../embeddedCode';
import { codeRanges, textPosition } from '../../embeddedCode/sourceMap';
import { again, done, loop } from '../../util/loop';
import type { AstNode } from '../../zshParser/ast';
import { foldAst } from '../../zshParser/ast';
import type { SourceRange } from '../../zshParser/lexer';
import type { Span, TokenType } from './types';

const keywords: ReadonlySet<string> = new Set([
  'if',
  'then',
  'else',
  'elif',
  'fi',
  'for',
  'select',
  'foreach',
  'repeat',
  'while',
  'until',
  'do',
  'done',
  'case',
  'in',
  'esac',
  'function',
  'time',
  'coproc',
  'end',
]);

type Progress = {
  readonly spans: ReadonlyArray<Span>;
  readonly words: ReadonlyArray<SourceRange>;
  readonly remaining: number;
};

function add(
  state: Progress,
  range: SourceRange,
  type: TokenType,
  priority: number,
  program: CodeProgram,
  maxSpans: number,
): Progress {
  if (state.remaining <= 0 || state.spans.length >= maxSpans) {
    return state;
  }

  const length = Math.min(range.end.offset - range.start.offset, state.remaining);
  const bounded =
    length < range.end.offset - range.start.offset
      ? { ...range, end: textPosition(program.lineStarts, range.start.offset + length) }
      : range;
  const physical = codeRanges(program.source, bounded, maxSpans - state.spans.length)
    .filter((range) => range.end.offset > range.start.offset)
    .map((range): Span => ({
      start: range.start.offset,
      end: range.end.offset,
      type,
      priority: program.depth * 100 + priority,
    }));

  return { ...state, remaining: state.remaining - length, spans: state.spans.concat(physical) };
}

function classify(
  state: Progress,
  node: AstNode,
  program: CodeProgram,
  maxSpans: number,
): Progress {
  if (node.kind === 'word') {
    const number = node.raw.length > 0 && [...node.raw].every((char) => char >= '0' && char <= '9');

    return add(
      { ...state, words: appendItems(state.words, node.range) },
      node.range,
      node.quoted ? 'string' : number ? 'number' : 'parameter',
      10,
      program,
      maxSpans,
    );
  }

  if (node.kind === 'commandName') {
    return add(state, node.range, 'function', 30, program, maxSpans);
  }

  if (node.kind === 'functionDefinition') {
    return node.names.reduce(
      (current, name) => add(current, name.range, 'function', 30, program, maxSpans),
      state,
    );
  }

  if (
    node.kind === 'variableReference' ||
    node.kind === 'parameterExpansion' ||
    node.kind === 'variableName'
  ) {
    return add(state, node.range, 'variable', 40, program, maxSpans);
  }

  return node.kind === 'precommandModifier' ||
    node.kind === 'pipelineModifier' ||
    node.kind === 'pipelineTiming'
    ? add(state, node.range, 'keyword', 20, program, maxSpans)
    : state;
}

function syntaxSpans(program: CodeProgram, maxSpans: number): Progress {
  const initial: Progress = {
    spans: collectArray(),
    words: collectArray(),
    remaining: program.content.length * 8,
  };
  const syntax = foldAst(program.file.ast, initial, (state, node) => {
    const classified = classify(state, node, program, maxSpans);
    const keyword =
      'keyword' in node
        ? add(classified, node.keyword, 'keyword', 20, program, maxSpans)
        : classified;
    const closed =
      'keyword' in node && 'close' in node && node.close
        ? add(keyword, node.close, 'keyword', 20, program, maxSpans)
        : keyword;

    return {
      state:
        'thenKeyword' in node && node.thenKeyword
          ? add(closed, node.thenKeyword, 'keyword', 20, program, maxSpans)
          : closed,
    };
  });

  return syntax;
}

function tokenSpans(program: CodeProgram, syntax: Progress, maxSpans: number): readonly Span[] {
  const sortedWords = syntax.words.toSorted(
    (left, right) => left.start.offset - right.start.offset,
  );
  const result = program.file.tokens.reduce(
    (previous, token) => {
      const covered = loop({ index: previous.wordIndex, end: previous.coveredEnd }, (current) =>
        current.index < sortedWords.length &&
        sortedWords[current.index].start.offset <= token.range.start.offset
          ? again({
              index: current.index + 1,
              end: Math.max(current.end, sortedWords[current.index].end.offset),
            })
          : done(current),
      );
      const type =
        token.kind === 'operator'
          ? 'operator'
          : token.kind === 'comment'
            ? 'comment'
            : token.kind === 'word' &&
                !token.quoted &&
                keywords.has(token.value) &&
                covered.end < token.range.end.offset
              ? 'keyword'
              : null;

      return {
        wordIndex: covered.index,
        coveredEnd: covered.end,
        rendering: type
          ? add(
              previous.rendering,
              token.range,
              type,
              type === 'comment' ? 50 : type === 'operator' ? 10 : 20,
              program,
              maxSpans,
            )
          : previous.rendering,
      };
    },
    { wordIndex: 0, coveredEnd: -1, rendering: syntax },
  );

  return result.rendering.spans;
}

/** 内側のASTに従って分類し、物理的に連続する元文書の範囲へ戻す。 */
export function programSpans(program: CodeProgram, maxSpans: number): readonly Span[] {
  const syntax = syntaxSpans(program, maxSpans);

  if (syntax.remaining <= 0 || syntax.spans.length >= maxSpans) {
    return syntax.spans;
  }

  return tokenSpans(program, syntax, maxSpans);
}

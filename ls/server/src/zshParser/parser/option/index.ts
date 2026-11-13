import type { OptionNode, WordNode } from '../../ast';
import type { SourceRange, Token } from '../../lexer';

type OptionNodeInput = {
  readonly range: SourceRange;
  readonly name: string;
  readonly value: WordNode | null;
};

function createOptionNode({
  range,
  name,
  value,
}: OptionNodeInput): OptionNode {
  return {
    kind: 'option',
    range,
    name,
    value,
  };
}

export function createOptionNodeFromToken(token: Token, value: WordNode | null): OptionNode {
  return createOptionNode({
    range: optionRange(token, value),
    name: token.value,
    value,
  });
}

export function createOptionNodeFromWord(word: WordNode, value: WordNode | null): OptionNode {
  return createOptionNode({
    range: word.range,
    name: word.raw,
    value,
  });
}

function optionRange(token: Token, value: WordNode | null): SourceRange {
  if (value) {
    return {
      start: token.range.start,
      end: value.range.end,
    };
  } else {
    return token.range;
  }
}

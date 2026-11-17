import { again, done, loop } from '../../../../util/loop';
import type { Token } from '../../../lexer';
import type { DelimiterKind } from '../../../lexer/delimiter';
import { delimitedEnd } from '../../../lexer/delimiter';
import { areAdjacentTokens } from '../../range';
import type { ExpansionNodeKind } from '../expansionNode';

export type ExpansionAfterWord = {
  readonly kind: ExpansionNodeKind;
  readonly tokens: readonly Token[];
  readonly endIndex: number;
};

function expansionForOperator(kind: Token['operatorKind']): ExpansionNodeKind | null {
  switch (kind) {
    case 'leftBrace':
      return 'parameterExpansion';
    case 'leftParen':
      return 'commandSubstitution';
    case 'arithmeticStart':
      return 'arithmeticExpansion';
    default:
      return null;
  }
}

function delimiterForOperator(kind: Token['operatorKind']): DelimiterKind {
  switch (kind) {
    case 'leftBrace':
      return 'brace';
    case 'arithmeticStart':
      return 'arithmetic';
    default:
      return 'paren';
  }
}

export function readExpansionAfterWord(
  tokens: readonly Token[],
  index: number,
): ExpansionAfterWord | null {
  const token = tokens[index];
  const next = tokens[index + 1];

  if (!token || !next || !token.value.endsWith('$') || !areAdjacentTokens(token, next)) {
    return null;
  }

  const kind = expansionForOperator(next.operatorKind);

  if (!kind) {
    return null;
  }

  const endIndex = findDelimitedTokenEnd(
    tokens,
    index + 1,
    delimiterForOperator(next.operatorKind),
  );

  return endIndex === null
    ? null
    : { kind, tokens: tokens.slice(index + 1, endIndex + 1), endIndex };
}

export function findNestedOperatorEnd({
  tokens,
  index,
  startOperatorKind,
  lexicalKind,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly depth: number;
  readonly lexicalKind?: DelimiterKind;
  readonly startOperatorKind: NonNullable<Token['operatorKind']>;
  readonly endOperatorKind: NonNullable<Token['operatorKind']>;
}): number | null {
  return findDelimitedTokenEnd(
    tokens,
    index,
    lexicalKind ?? delimiterForOperator(startOperatorKind),
  );
}

function findDelimitedTokenEnd(
  tokens: readonly Token[],
  index: number,
  kind: DelimiterKind,
): number | null {
  const text = tokens
    .slice(index)
    .map((token) => token.value)
    .join('');
  const end = delimitedEnd(text, 0, kind);

  if (end === null) {
    return null;
  }

  const initial = { index, length: 0 };

  return loop<typeof initial, number | null>(initial, (current) => {
    const token = tokens[current.index];

    if (!token) {
      return done(null);
    }

    const length = current.length + token.value.length;

    return length >= end ? done(current.index) : again({ index: current.index + 1, length });
  });
}

import type { AssignNode } from '../../ast';
import { isVariableName } from './variableName';

const Equals = '=';
const PlusEquals = '+=';
const LeftBracket = '[';
const RightBracket = ']';
const LeftParen = '(';
const RightParen = ')';
const LeftBrace = '{';
const RightBrace = '}';

export type AssignmentSyntax = {
  readonly operator: AssignNode['operator'];
  readonly nameStart: number;
  readonly nameEnd: number;
  readonly subscriptStart: number | null;
  readonly subscriptEnd: number | null;
  readonly valueStart: number;
  readonly valueEnd: number;
};

type AssignmentOperator = {
  readonly index: number;
  readonly operator: AssignNode['operator'];
};

export function isAssignmentPrefix(value: string): boolean {
  const syntax = readAssignmentSyntax(value);

  return syntax !== null && syntax.valueStart === value.length;
}

export function readAssignmentSyntax(value: string): AssignmentSyntax | null {
  const operator = findAssignmentOperator(value);

  if (!operator) {
    return null;
  } else {
    return readAssignmentTarget({
      value,
      operator,
    });
  }
}

function readAssignmentTarget({
  value,
  operator,
}: {
  readonly value: string;
  readonly operator: AssignmentOperator;
}): AssignmentSyntax | null {
  const target = value.slice(0, operator.index);
  const subscriptOpenIndex = target.indexOf(LeftBracket);

  if (isVariableName(target)) {
    return {
      operator: operator.operator,
      nameStart: 0,
      nameEnd: operator.index,
      subscriptStart: null,
      subscriptEnd: null,
      valueStart: operator.index + operator.operator.length,
      valueEnd: value.length,
    };
  } else if (subscriptOpenIndex <= 0 || !target.endsWith(RightBracket)) {
    return null;
  } else if (!isVariableName(target.slice(0, subscriptOpenIndex))) {
    return null;
  } else {
    return {
      operator: operator.operator,
      nameStart: 0,
      nameEnd: subscriptOpenIndex,
      subscriptStart: subscriptOpenIndex + LeftBracket.length,
      subscriptEnd: operator.index - RightBracket.length,
      valueStart: operator.index + operator.operator.length,
      valueEnd: value.length,
    };
  }
}

function findAssignmentOperator(value: string): AssignmentOperator | null {
  let bracketDepth = 0;
  let parenDepth = 0;
  let braceDepth = 0;

  for (let index = 0; index < value.length; index += 1) {
    const char = value[index];
    const canReadOperator = bracketDepth === 0 && parenDepth === 0 && braceDepth === 0;

    if (canReadOperator && value.startsWith(PlusEquals, index)) {
      return { index, operator: PlusEquals };
    } else if (canReadOperator && char === Equals) {
      return { index, operator: Equals };
    }

    bracketDepth = nextDepth({ depth: bracketDepth, char, open: LeftBracket, close: RightBracket });
    parenDepth = nextDepth({ depth: parenDepth, char, open: LeftParen, close: RightParen });
    braceDepth = nextDepth({ depth: braceDepth, char, open: LeftBrace, close: RightBrace });
  }

  return null;
}

function nextDepth({
  depth,
  char,
  open,
  close,
}: {
  readonly depth: number;
  readonly char: string;
  readonly open: string;
  readonly close: string;
}): number {
  if (char === open) {
    return depth + 1;
  } else if (char === close && depth > 0) {
    return depth - 1;
  } else {
    return depth;
  }
}

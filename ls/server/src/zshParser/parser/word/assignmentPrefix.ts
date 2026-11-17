import { again, done, loop } from '../../../util/loop';
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
  const initial = { index: 0, bracketDepth: 0, parenDepth: 0, braceDepth: 0 };
  return loop<typeof initial, AssignmentOperator | null>(initial, (state) => {
    if (state.index >= value.length) {
      return done(null);
    }
    const char = value[state.index];
    const canReadOperator =
      state.bracketDepth === 0 && state.parenDepth === 0 && state.braceDepth === 0;
    if (canReadOperator && value.startsWith(PlusEquals, state.index)) {
      return done({ index: state.index, operator: PlusEquals });
    }
    if (canReadOperator && char === Equals) {
      return done({ index: state.index, operator: Equals });
    }
    return again({
      index: state.index + 1,
      bracketDepth: nextDepth({
        depth: state.bracketDepth,
        char,
        open: LeftBracket,
        close: RightBracket,
      }),
      parenDepth: nextDepth({ depth: state.parenDepth, char, open: LeftParen, close: RightParen }),
      braceDepth: nextDepth({ depth: state.braceDepth, char, open: LeftBrace, close: RightBrace }),
    });
  });
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

import { appendItems, collectArray } from '../../../../util/collections';
import { again, done, loop } from '../../../../util/loop';
import type { CaseArmNode, WordNode } from '../../../ast';
import type { ParserContext } from '../../context';
import type { NodeResult, ParseState } from '../../state';
import { addDiagnostic, advanceState, currentToken, skipTrivia } from '../../state';
import { readWordNode } from '../../word/composite';
import { endAt, isWordStart, skipCommandTerm, takeKeyword } from './syntax';
import type { CompoundContents } from './types';

function readSubject(state: ParseState): NodeResult<WordNode | null> {
  const current = skipTrivia(state);

  return isWordStart(current)
    ? readWordNode(current)
    : {
        node: null,
        state: addDiagnostic({
          state: current,
          kind: 'unexpectedToken',
          message: 'Expected case subject',
          tokens: [currentToken(current)],
        }),
      };
}

function readPatterns(state: ParseState): {
  readonly patterns: readonly WordNode[];
  readonly state: ParseState;
} {
  const initial = { current: state, patterns: collectArray<WordNode>() };

  return loop<
    typeof initial,
    {
      readonly patterns: readonly WordNode[];
      readonly state: ParseState;
    }
  >(initial, (progress) => {
    const token = currentToken(progress.current);

    if (token.kind === 'eof' || token.operatorKind === 'rightParen') {
      return done({ patterns: progress.patterns, state: progress.current });
    }

    const word = isWordStart(progress.current) ? readWordNode(progress.current) : null;

    return again({
      current: skipTrivia(word?.state ?? advanceState(progress.current)),
      patterns: word ? appendItems(progress.patterns, word.node) : progress.patterns,
    });
  });
}

function readCaseArm(state: ParseState, context: ParserContext): NodeResult<CaseArmNode> {
  const open = currentToken(state);
  const patterns = readPatterns(open.operatorKind === 'leftParen' ? advanceState(state) : state);
  const diagnosed =
    patterns.patterns.length === 0
      ? addDiagnostic({
          state: patterns.state,
          kind: 'unexpectedToken',
          message: 'Expected case pattern',
          tokens: [currentToken(patterns.state)],
        })
      : patterns.state;
  const current =
    currentToken(diagnosed).operatorKind === 'rightParen' ? advanceState(diagnosed) : diagnosed;
  const body = context.parseNestedList(
    current,
    (token) =>
      endAt('esac')(token) ||
      token.operatorKind === 'doubleSemicolon' ||
      token.operatorKind === 'caseFallthrough' ||
      token.operatorKind === 'caseContinue',
  );
  const close = currentToken(body.state);
  const termination =
    close.value === ';;' || close.value === ';&' || close.value === ';|' ? close.value : null;

  return {
    node: {
      kind: 'caseArm',
      range: { start: open.range.start, end: termination ? close.range.end : body.node.range.end },
      patterns: patterns.patterns,
      body: body.node,
      terminator: termination ? close.range : null,
      termination,
    },
    state: body.state,
  };
}

export function readCaseBody(
  state: ParseState,
  context: ParserContext,
): NodeResult<CompoundContents> {
  const subject = readSubject(state);
  const afterIn = skipCommandTerm(takeKeyword(skipCommandTerm(subject.state), 'in').state);
  const initial = { current: afterIn, arms: collectArray<CaseArmNode>() };
  const parsed = loop<typeof initial, typeof initial>(initial, (progress) => {
    if (endAt('esac')(currentToken(progress.current))) {
      return done(progress);
    }

    const arm = readCaseArm(progress.current, context);
    const arms = appendItems(progress.arms, arm.node);

    return arm.node.termination
      ? again({ current: skipCommandTerm(advanceState(arm.state)), arms })
      : done({ current: arm.state, arms });
  });

  return {
    node: { kind: 'caseCommand', subject: subject.node, arms: parsed.arms },
    state: parsed.current,
  };
}

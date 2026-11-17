import type { CaseArmNode, WordNode } from '../../../ast';
import type { ParserContext } from '../../context';
import type { NodeResult, ParseState } from '../../state';
import { addDiagnostic, advanceState, currentToken, skipTrivia } from '../../state';
import { readWordNode } from '../../word/composite';
import { endAt, isWordStart, skipTerms, takeKeyword } from './syntax';
import type { CompoundContents } from './types';
export function readCaseBody(
  state: ParseState,
  context: ParserContext,
): NodeResult<CompoundContents> {
  let current = state;
  let subject: WordNode | null = null;

  current = skipTrivia(current);

  if (isWordStart(current)) {
    const word = readWordNode(current);
    subject = word.node;
    current = word.state;
  } else {
    current = addDiagnostic({
      state: current,
      kind: 'unexpectedToken',
      message: 'Expected case subject',
      tokens: [currentToken(current)],
    });
  }

  current = skipTerms(takeKeyword(skipTerms(current), 'in').state);

  const collected: CaseArmNode[] = [];

  while (!endAt('esac')(currentToken(current))) {
    const armStart = currentToken(current);
    if (armStart.operatorKind === 'leftParen') {
      current = advanceState(current);
    }
    const patterns: WordNode[] = [];
    while (
      currentToken(current).kind !== 'eof' &&
      currentToken(current).operatorKind !== 'rightParen'
    ) {
      const token = currentToken(current);
      if (isWordStart(current)) {
        const word = readWordNode(current);
        patterns.push(word.node);
        current = word.state;
      } else {
        current = advanceState(current);
      }
      current = skipTrivia(current);
    }
    if (patterns.length === 0) {
      current = addDiagnostic({
        state: current,
        kind: 'unexpectedToken',
        message: 'Expected case pattern',
        tokens: [currentToken(current)],
      });
    }
    if (currentToken(current).operatorKind === 'rightParen') {
      current = advanceState(current);
    }
    const result = context.parseNestedList(
      current,
      (token) =>
        endAt('esac')(token) ||
        token.operatorKind === 'doubleSemicolon' ||
        token.operatorKind === 'caseFallthrough' ||
        token.operatorKind === 'caseContinue',
    );
    current = result.state;
    const token = currentToken(current);
    const termination =
      token.value === ';;' || token.value === ';&' || token.value === ';|' ? token.value : null;
    collected.push({
      kind: 'caseArm',
      range: {
        start: armStart.range.start,
        end: termination ? token.range.end : result.node.range.end,
      },
      patterns,
      body: result.node,
      terminator: termination ? token.range : null,
      termination,
    });
    if (!termination) {
      break;
    }
    current = skipTerms(advanceState(current));
  }

  return { node: { kind: 'caseCommand', subject, arms: collected }, state: current };
}

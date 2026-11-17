import { again, done, loop } from '../../../util/loop';
import type { PipelineModifierNode } from '../../ast';
import type { Token } from '../../lexer';
import type { ParseState } from '../state';
import { addDiagnostic, advanceState, currentToken, skipTrivia } from '../state';

type PipelineModifierResult = {
  readonly modifier: PipelineModifierNode | null;
  readonly state: ParseState;
};

export function readPipelineModifier(state: ParseState): PipelineModifierResult {
  const current = skipTrivia(state);
  const token = currentToken(current);
  const type = pipelineModifierType(token);

  if (!type) {
    return {
      modifier: null,
      state: current,
    };
  } else {
    return {
      modifier: {
        kind: 'pipelineModifier',
        range: token.range,
        type,
      },
      state: skipExtraPipelineModifiers(advanceState(current)),
    };
  }
}

function skipExtraPipelineModifiers(state: ParseState): ParseState {
  return loop(skipTrivia(state), (current) => {
    const token = currentToken(current);
    return pipelineModifierType(token)
      ? again(
          skipTrivia(
            advanceState(
              addDiagnostic({
                state: current,
                kind: 'unexpectedToken',
                message: 'Multiple pipeline modifiers are not allowed: ' + token.value,
                tokens: [token],
              }),
            ),
          ),
        )
      : done(current);
  });
}

function pipelineModifierType(token: Token): PipelineModifierNode['type'] | null {
  if (token.kind !== 'word') {
    return null;
  } else if (token.value === '!') {
    return 'bang';
  } else if (token.value === 'coproc') {
    return 'coproc';
  } else {
    return null;
  }
}

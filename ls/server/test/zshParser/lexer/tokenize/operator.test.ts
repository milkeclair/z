import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

function operatorSummaries(input: string) {
  return tokenSummaries(input)
    .filter((token) => token.kind === 'operator')
    .map((token) => ({
      value: token.value,
      operatorKind: token.operatorKind,
    }));
}

describe('tokenize@operator', () => {
  test('定義済みoperatorをすべてトークン化する', () => {
    expect(
      operatorSummaries('&>> <<< <<- && || |& ;; ;& ;| [[ ]] (( )) >> << >| <> <& >& &> ( ) { } ; | & < >'),
    ).toEqual([
      { value: '&>>', operatorKind: 'redirect' },
      { value: '<<<', operatorKind: 'redirect' },
      { value: '<<-', operatorKind: 'redirect' },
      { value: '&&', operatorKind: 'andIf' },
      { value: '||', operatorKind: 'orIf' },
      { value: '|&', operatorKind: 'pipeErr' },
      { value: ';;', operatorKind: 'doubleSemicolon' },
      { value: ';&', operatorKind: 'caseFallthrough' },
      { value: ';|', operatorKind: 'caseContinue' },
      { value: '[[', operatorKind: 'conditionStart' },
      { value: ']]', operatorKind: 'conditionEnd' },
      { value: '((', operatorKind: 'arithmeticStart' },
      { value: '))', operatorKind: 'arithmeticEnd' },
      { value: '>>', operatorKind: 'redirect' },
      { value: '<<', operatorKind: 'redirect' },
      { value: '>|', operatorKind: 'redirect' },
      { value: '<>', operatorKind: 'redirect' },
      { value: '<&', operatorKind: 'redirect' },
      { value: '>&', operatorKind: 'redirect' },
      { value: '&>', operatorKind: 'redirect' },
      { value: '(', operatorKind: 'leftParen' },
      { value: ')', operatorKind: 'rightParen' },
      { value: '{', operatorKind: 'leftBrace' },
      { value: '}', operatorKind: 'rightBrace' },
      { value: ';', operatorKind: 'semicolon' },
      { value: '|', operatorKind: 'pipe' },
      { value: '&', operatorKind: 'background' },
      { value: '<', operatorKind: 'redirect' },
      { value: '>', operatorKind: 'redirect' },
    ]);
  });

  test('重なり合うoperatorは最長一致で読む', () => {
    expect(operatorSummaries('&>> &> <<< <<- << ;; ;& ;| && || |& (( (')).toEqual([
      { value: '&>>', operatorKind: 'redirect' },
      { value: '&>', operatorKind: 'redirect' },
      { value: '<<<', operatorKind: 'redirect' },
      { value: '<<-', operatorKind: 'redirect' },
      { value: '<<', operatorKind: 'redirect' },
      { value: ';;', operatorKind: 'doubleSemicolon' },
      { value: ';&', operatorKind: 'caseFallthrough' },
      { value: ';|', operatorKind: 'caseContinue' },
      { value: '&&', operatorKind: 'andIf' },
      { value: '||', operatorKind: 'orIf' },
      { value: '|&', operatorKind: 'pipeErr' },
      { value: '((', operatorKind: 'arithmeticStart' },
      { value: '(', operatorKind: 'leftParen' },
    ]);
  });
});

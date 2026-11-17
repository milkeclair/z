import * as Immutable from 'immutable';
import { again, done, loop } from '../../util/loop';
import { horizontalWhitespaceEnd } from '../../util/text';
import { parseLiteralChoice } from './literalChoice';

type CodeTypeAnnotation = {
  readonly end: number;
  readonly literalValues: readonly string[];
};

type ChoiceProgress = {
  readonly offset: number;
  readonly values: Immutable.List<string>;
};

/** code型と許可値を読み、閉じ角括弧の次の位置を返す。 */
export function parseCodeParameterType(text: string, start: number): CodeTypeAnnotation | null {
  if (!text.startsWith('[code', start)) {
    return null;
  }

  return loop<ChoiceProgress, CodeTypeAnnotation | null>(
    { offset: start + 5, values: Immutable.List() },
    ({ offset, values }) => {
      const next = horizontalWhitespaceEnd(text, offset);

      switch (text[next]) {
        case ']':
          return done({ end: next + 1, literalValues: values.toArray() });
        case '|': {
          const choice = parseLiteralChoice(text, horizontalWhitespaceEnd(text, next + 1));

          return choice
            ? again({ offset: choice.end, values: values.push(choice.value) })
            : done(null);
        }
        default:
          return done(null);
      }
    },
  );
}

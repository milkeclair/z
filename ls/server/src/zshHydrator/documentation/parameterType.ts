import { appendItems, collectArray } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import { horizontalWhitespaceEnd } from '../../util/text';
import { parseLiteralChoice } from './literalChoice';

type CodeTypeAnnotation = {
  readonly end: number;
  readonly literalValues: readonly string[];
};

type ChoiceProgress = {
  readonly offset: number;
  readonly values: ReadonlyArray<string>;
};

/** code型と許可値を読み、閉じ角括弧の次の位置を返す。 */
export function parseCodeParameterType(text: string, start: number): CodeTypeAnnotation | null {
  if (!text.startsWith('[code', start)) {
    return null;
  }

  return loop<ChoiceProgress, CodeTypeAnnotation | null>(
    { offset: start + 5, values: collectArray() },
    ({ offset, values }) => {
      const next = horizontalWhitespaceEnd(text, offset);

      switch (text[next]) {
        case ']':
          return done({ end: next + 1, literalValues: values });
        case '|': {
          const choice = parseLiteralChoice(text, horizontalWhitespaceEnd(text, next + 1));

          return choice
            ? again({ offset: choice.end, values: appendItems(values, choice.value) })
            : done(null);
        }
        default:
          return done(null);
      }
    },
  );
}

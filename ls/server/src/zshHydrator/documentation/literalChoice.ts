import { again, done, loop } from '../../util/loop';

export type LiteralChoice = {
  readonly value: string;
  readonly end: number;
};

type LiteralProgress = {
  readonly offset: number;
  readonly value: string;
};

/** 型アノテーションの許可値を読み、引用符を除いた値と次の位置を返す。 */
export function parseLiteralChoice(text: string, start: number): LiteralChoice | null {
  const quote = text[start];

  if (quote !== "'" && quote !== '"') {
    return null;
  }

  return loop<LiteralProgress, LiteralChoice | null>(
    { offset: start + 1, value: '' },
    ({ offset, value }) => {
      if (offset >= text.length) {
        return done(null);
      }

      const char = text[offset];

      if (char === quote) {
        return done({ value, end: offset + 1 });
      }

      const escaped = char === '\\' && (text[offset + 1] === quote || text[offset + 1] === '\\');
      const valueOffset = offset + (escaped ? 1 : 0);

      return again({ offset: valueOffset + 1, value: value + (text[valueOffset] ?? '') });
    },
  );
}

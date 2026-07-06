import { SpecialCharacters } from '../../character';
import { advance, eof } from '../../cursor';
import type { Cursor } from '../../cursor';
import { scan } from '../../scan';
import type { ReadResult } from './result';

type TextReadState = {
  readonly accumulatedText: string;
  readonly cursor: Cursor;
};

export function readTextWhile({
  cursor,
  shouldContinue,
}: {
  readonly cursor: Cursor;
  readonly shouldContinue: (cursor: Cursor) => boolean;
}): ReadResult<string> {
  const result = scan({
    state: {
      accumulatedText: SpecialCharacters.empty,
      cursor,
    },
    done: (state: TextReadState) => eof(state.cursor) || !shouldContinue(state.cursor),
    step: (state: TextReadState): TextReadState => {
      const result = advance(state.cursor);

      return {
        accumulatedText: state.accumulatedText + result.value,
        cursor: result.cursor,
      };
    },
  });

  return { value: result.accumulatedText, cursor: result.cursor };
}

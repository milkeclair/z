import type { OperatorDefinition } from '../../character';
import type { Cursor } from '../../cursor';
import { readComment } from './comment';
import { readContinuation, readNewline } from './line';
import { readOperator } from './operator';
import { readWhitespace } from './whitespace';
import { readWord } from './word';
import type { WordBoundary } from './word';

type ReaderContext = {
  readonly sourceFile: string;
};

export function Reader({ sourceFile }: ReaderContext) {
  return {
    newline(cursor: Cursor) {
      return readNewline(cursor);
    },

    continuation(cursor: Cursor) {
      return readContinuation(cursor);
    },

    whitespace(cursor: Cursor) {
      return readWhitespace({ sourceFile, cursor });
    },

    comment(cursor: Cursor) {
      return readComment({ sourceFile, cursor });
    },

    operator(cursor: Cursor, operator: OperatorDefinition) {
      return readOperator({ sourceFile, cursor, operator });
    },

    word(cursor: Cursor, isWordBoundary: WordBoundary) {
      return readWord({ sourceFile, cursor, isWordBoundary });
    },
  };
}

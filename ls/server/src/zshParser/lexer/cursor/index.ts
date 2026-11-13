import { SpecialCharacters } from '../character';
import { scan } from '../scan';
import type { SourcePosition } from '../token';

export type Cursor = {
  readonly text: string;
  readonly position: SourcePosition;
};

type AdvanceResult = {
  readonly value: string;
  readonly cursor: Cursor;
};

type AdvanceState = {
  readonly cursor: Cursor;
  readonly remaining: number;
  readonly accumulatedText: string;
};

export function createCursor(text: string): Cursor {
  return {
    text,
    position: {
      offset: 0,
      line: 0,
      character: 0,
    },
  };
}

export function eof(cursor: Cursor): boolean {
  return cursor.position.offset >= cursor.text.length;
}

export function position(cursor: Cursor): SourcePosition {
  return cursor.position;
}

export function current(cursor: Cursor): string {
  return cursor.text[cursor.position.offset] ?? SpecialCharacters.empty;
}

export function startsWith(cursor: Cursor, value: string): boolean {
  return cursor.text.startsWith(value, cursor.position.offset);
}

function advanceOne(cursor: Cursor, char: string): Cursor {
  const nextChar = cursor.text[cursor.position.offset + 1] ?? SpecialCharacters.empty;
  const newLine =
    char === SpecialCharacters.lineFeed ||
    (char === SpecialCharacters.carriageReturn && nextChar !== SpecialCharacters.lineFeed);

  return {
    text: cursor.text,
    position: {
      offset: cursor.position.offset + 1,
      line: newLine ? cursor.position.line + 1 : cursor.position.line,
      character: newLine ? 0 : cursor.position.character + 1,
    },
  };
}

function advanceDone(state: AdvanceState): boolean {
  return state.remaining <= 0 || eof(state.cursor);
}

function advanceStep(state: AdvanceState): AdvanceState {
  const char = current(state.cursor);

  return {
    cursor: advanceOne(state.cursor, char),
    remaining: state.remaining - 1,
    accumulatedText: state.accumulatedText + char,
  };
}

export function advance(cursor: Cursor, length = 1): AdvanceResult {
  const result = scan({
    state: {
      cursor,
      remaining: length,
      accumulatedText: SpecialCharacters.empty,
    },
    done: advanceDone,
    step: advanceStep,
  });

  return {
    value: result.accumulatedText,
    cursor: result.cursor,
  };
}

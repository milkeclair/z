import { produce } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import type { TextDocument } from '../../vscode_type';
import { codeTokenTypes, MAX_HIGHLIGHT_SPANS, type Span } from './types';

type Encoded = {
  readonly lastLine: number;
  readonly lastCharacter: number;
};

function encodeSpan(
  document: TextDocument,
  content: string,
  span: Span,
  initial: Encoded,
  data: number[],
): Encoded {
  return loop<
    {
      readonly offset: number;
      readonly encoded: Encoded;
    },
    Encoded
  >({ offset: span.start, encoded: initial }, (state) => {
    const { offset, encoded } = state;

    if (offset >= span.end) {
      return done(encoded);
    }

    const start = document.positionAt(offset);
    const next = document.offsetAt({ line: start.line + 1, character: 0 });
    const end = loop(Math.min(span.end, next), (end) =>
      end > offset && (content[end - 1] === '\n' || content[end - 1] === '\r')
        ? again(end - 1)
        : done(end),
    );
    if (end > offset) {
      data.push(
        start.line - encoded.lastLine,
        start.line === encoded.lastLine ? start.character - encoded.lastCharacter : start.character,
        end - offset,
        codeTokenTypes.indexOf(span.type),
        0,
      );
    }
    const result =
      end > offset ? { lastLine: start.line, lastCharacter: start.character } : encoded;

    return data.length >= MAX_HIGHLIGHT_SPANS * 5 || next <= offset || next >= span.end
      ? done(result)
      : again({ offset: next, encoded: result });
  });
}

export function encodeSpans(document: TextDocument, spans: readonly Span[]): readonly number[] {
  const content = document.getText();
  return produce<readonly number[]>([], (data) => {
    const initial = { index: 0, encoded: { lastLine: 0, lastCharacter: 0 } };

    loop<typeof initial, void>(initial, (state) => {
      const span = spans[state.index];

      if (!span || data.length >= MAX_HIGHLIGHT_SPANS * 5) {
        return done(undefined);
      }

      return again({
        index: state.index + 1,
        encoded: encodeSpan(document, content, span, state.encoded, data),
      });
    });
  });
}

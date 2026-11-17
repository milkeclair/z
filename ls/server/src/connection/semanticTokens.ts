import { collectArray } from '../util/collections';
import type { CodeProgram } from '../embeddedCode';
import { again, done, loop } from '../util/loop';
import type { TextDocument } from '../vscode_type';
import { disjoint } from './semanticTokens/disjoint';
import { encodeSpans } from './semanticTokens/encode';
import { programSpans } from './semanticTokens/spans';
import { MAX_HIGHLIGHT_SPANS, type Span } from './semanticTokens/types';

export { codeTokenTypes } from './semanticTokens/types';

/** 解析済みのコード引数だけを色分けし、標準semantic token形式へ変換する。 */
export function zSemanticTokens({
  document,
  programs,
}: {
  readonly document: TextDocument;
  readonly programs: readonly CodeProgram[];
}): {
  readonly data: readonly number[];
} {
  const initial = { index: 0, spans: collectArray<Span>() };
  const spans = loop<typeof initial, readonly Span[]>(initial, (state) => {
    const program = programs[state.index];

    if (!program || state.spans.length >= MAX_HIGHLIGHT_SPANS) {
      return done(state.spans);
    }

    return again({
      index: state.index + 1,
      spans: state.spans.concat(programSpans(program, MAX_HIGHLIGHT_SPANS - state.spans.length)),
    });
  });

  return { data: encodeSpans(document, disjoint(spans)) };
}

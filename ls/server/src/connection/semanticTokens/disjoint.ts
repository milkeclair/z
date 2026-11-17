import { makeMap, produce } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import type { Span } from './types';

type BoundaryEvent = {
  readonly offset: number;
  readonly start: boolean;
  readonly span: Span;
  readonly id: number;
};

type ActiveSpans = ReadonlyMap<number, Span>;

function boundaryEvents(spans: readonly Span[]): readonly BoundaryEvent[] {
  return spans
    .flatMap((span, id) => [
      { offset: span.start, start: true, span, id },
      { offset: span.end, start: false, span, id },
    ])
    .toSorted((left, right) => left.offset - right.offset);
}

function visibleSpan(active: ActiveSpans): Span | undefined {
  return [...active.values()].reduce<Span | undefined>(
    (selected, span) => (!selected || span.priority > selected.priority ? span : selected),
    undefined,
  );
}

function appendSpan(spans: Span[], selected: Span | undefined, start: number, end: number): void {
  if (!selected || end <= start) {
    return;
  }

  const last = spans.at(-1);

  if (last && last.end === start && last.type === selected.type) {
    spans[spans.length - 1] = { ...last, end };
    return;
  }

  spans.push({ ...selected, start, end });
}

function applyBoundaryEvents(
  events: readonly BoundaryEvent[],
  index: number,
  active: Map<number, Span>,
): number {
  const offset = events[index].offset;

  while (events[index]?.offset === offset) {
    const event = events[index];

    if (event.start) {
      active.set(event.id, event.span);
    } else {
      active.delete(event.id);
    }

    index += 1;
  }

  return index;
}

/** 外側の文字列より深いコードを優先し、重複しない範囲へ整列する。 */
export function disjoint(spans: readonly Span[]): readonly Span[] {
  const events = boundaryEvents(spans);

  const initial: { readonly active: ActiveSpans; readonly spans: readonly Span[] } = {
    active: makeMap(),
    spans: [],
  };

  return produce(initial, (draft) => {
    loop({ offset: 0, index: 0 }, (state) => {
      const event = events[state.index];

      if (!event) return done(undefined);

      appendSpan(draft.spans, visibleSpan(draft.active), state.offset, event.offset);
      const index = applyBoundaryEvents(events, state.index, draft.active);

      return again({ offset: event.offset, index });
    });
  }).spans;
}

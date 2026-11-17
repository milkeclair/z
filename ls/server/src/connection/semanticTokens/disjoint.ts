import * as Immutable from 'immutable';
import { again, done, loop } from '../../util/loop';
import type { Span } from './types';

type BoundaryEvent = {
  readonly offset: number;
  readonly start: boolean;
  readonly span: Span;
  readonly id: number;
};

type ActiveSpans = Immutable.OrderedMap<number, Span>;

function boundaryEvents(spans: readonly Span[]): readonly BoundaryEvent[] {
  return spans
    .flatMap((span, id) => [
      { offset: span.start, start: true, span, id },
      { offset: span.end, start: false, span, id },
    ])
    .toSorted((left, right) => left.offset - right.offset);
}

function visibleSpan(active: ActiveSpans): Span | undefined {
  return active.reduce<Span | undefined>(
    (selected, span) => (!selected || span.priority > selected.priority ? span : selected),
    undefined,
  );
}

function appendSpan(
  spans: Immutable.List<Span>,
  selected: Span | undefined,
  start: number,
  end: number,
): Immutable.List<Span> {
  if (!selected || end <= start) {
    return spans;
  }

  const last = spans.last();

  if (last && last.end === start && last.type === selected.type) {
    return spans.set(-1, { ...last, end });
  }

  return spans.push({ ...selected, start, end });
}

function applyBoundaryEvents(events: readonly BoundaryEvent[], index: number, active: ActiveSpans) {
  const offset = events[index].offset;

  return loop({ index, active }, (current) => {
    const event = events[current.index];

    if (!event || event.offset !== offset) {
      return done(current);
    }

    return again({
      index: current.index + 1,
      active: event.start
        ? current.active.set(event.id, event.span)
        : current.active.delete(event.id),
    });
  });
}

/** 外側の文字列より深いコードを優先し、重複しない範囲へ整列する。 */
export function disjoint(spans: readonly Span[]): readonly Span[] {
  const events = boundaryEvents(spans);
  const initial = {
    offset: 0,
    index: 0,
    active: Immutable.OrderedMap<number, Span>(),
    spans: Immutable.List<Span>(),
  };

  return loop<typeof initial, readonly Span[]>(initial, (state) => {
    const event = events[state.index];

    if (!event) {
      return done(state.spans.toArray());
    }

    const spans = appendSpan(state.spans, visibleSpan(state.active), state.offset, event.offset);
    const next = applyBoundaryEvents(events, state.index, state.active);

    return again({ offset: event.offset, index: next.index, active: next.active, spans });
  });
}

import { List, OrderedMap } from 'immutable';
import { again, done, loop } from '../../util/loop';
import type { Span } from './types';

/** 外側の文字列より深いコードを優先し、重複しない範囲へ整列する。 */
export function disjoint(spans: readonly Span[]): readonly Span[] {
  const events = spans
    .flatMap((span, id) => [
      { offset: span.start, start: true, span, id },
      { offset: span.end, start: false, span, id },
    ])
    .toSorted((left, right) => left.offset - right.offset);
  const initial = {
    previous: 0,
    index: 0,
    active: OrderedMap<number, Span>(),
    result: List<Span>(),
  };
  return loop<typeof initial, readonly Span[]>(initial, (state) => {
    const event = events[state.index];
    if (!event) {
      return done(state.result.toArray());
    }
    const offset = event.offset;
    const selected = state.active
      .valueSeq()
      .reduce<
        Span | undefined
      >((best, span) => (!best || span.priority > best.priority ? span : best), undefined);
    const last = state.result.last();
    const result =
      selected && offset > state.previous
        ? last && last.end === state.previous && last.type === selected.type
          ? state.result.set(-1, { ...last, end: offset })
          : state.result.push({ ...selected, start: state.previous, end: offset })
        : state.result;
    const group = loop({ index: state.index, active: state.active }, (current) => {
      const event = events[current.index];
      return event && event.offset === offset
        ? again({
            index: current.index + 1,
            active: event.start
              ? current.active.set(event.id, event.span)
              : current.active.delete(event.id),
          })
        : done(current);
    });
    return again({ previous: offset, index: group.index, active: group.active, result });
  });
}

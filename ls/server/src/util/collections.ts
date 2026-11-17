import { castDraft, enableMapSet, Immer, type Draft } from 'immer';

enableMapSet();

// ASTやSDKから借りた値には凍結を適用せず、公開する型で読み取り専用にする。
const immer = new Immer({ autoFreeze: false });

export function produce<State>(state: State, update: (draft: Draft<State>) => void): State {
  return immer.produce(state, update);
}

export function collectArray<Value>(values: Iterable<Value> = []): readonly Value[] {
  return Array.from(values);
}

export function appendItems<Value>(
  values: readonly Value[],
  ...added: readonly Value[]
): readonly Value[] {
  return [...values, ...added];
}

export function replaceItem<Value>(
  values: readonly Value[],
  index: number,
  value: Value,
): readonly Value[] {
  return values.with(index, value);
}

export function makeMap<Key, Value>(
  entries?: Iterable<readonly [Key, Value]>,
): ReadonlyMap<Key, Value> {
  return new Map(entries);
}

export function makeSet<Value>(values?: Iterable<Value>): ReadonlySet<Value> {
  return new Set(values);
}

export function setEntry<Key, Value>(
  map: ReadonlyMap<Key, Value>,
  key: Key,
  value: Value,
): ReadonlyMap<Key, Value> {
  return produce(map, (draft) => {
    draft.set(castDraft(key), castDraft(value));
  });
}

export function addValue<Value>(set: ReadonlySet<Value>, value: Value): ReadonlySet<Value> {
  return produce(set, (draft) => {
    draft.add(castDraft(value));
  });
}

export function deleteValue<Value>(set: ReadonlySet<Value>, value: Value): ReadonlySet<Value> {
  return produce(set, (draft) => {
    draft.delete(castDraft(value));
  });
}

export function unionValues<Value>(
  set: ReadonlySet<Value>,
  values: Iterable<Value>,
): ReadonlySet<Value> {
  return new Set([...set, ...values]);
}

export function mapValues<Key, Value, NewValue>(
  map: ReadonlyMap<Key, Value>,
  transform: (value: Value) => NewValue,
): readonly (readonly [Key, NewValue])[] {
  return [...map].map(([key, value]) => [key, transform(value)] as const);
}

export function numberRange(
  start: number,
  end: number,
  step = 1,
): IteratorObject<number, undefined, unknown> {
  return Iterator.from({
    next(): IteratorResult<number, undefined> {
      if (step > 0 ? start >= end : start <= end) {
        return { done: true, value: undefined };
      }

      const value = start;
      start += step;

      return { done: false, value };
    },
  });
}

function* prefix<Value>(
  values: Iterable<Value>,
  keep: (value: Value) => boolean,
): Generator<Value> {
  for (const value of values) {
    if (!keep(value)) return;
    yield value;
  }
}

export function takeWhile<Value>(values: Iterable<Value>, keep: (value: Value) => boolean) {
  return Iterator.from(prefix(values, keep));
}

export function skipWhile<Value>(
  values: readonly Value[],
  skip: (value: Value) => boolean,
): readonly Value[] {
  const start = values.findIndex((value) => !skip(value));

  return start < 0 ? [] : values.slice(start);
}

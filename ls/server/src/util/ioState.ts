import { newIORef } from 'fp-ts/IORef';

export type IOState<State> = {
  readonly read: () => State;
  readonly replace: (next: State) => void;
  readonly update: (transition: (previous: State) => State) => void;
};

/** 接続・プロセスなどのI/O境界で、不変の値を参照し直す。データの更新処理は次の値を返す。 */
export function createIOState<State>(initial: State): IOState<State> {
  const reference = newIORef(initial)();
  return {
    read: reference.read,
    replace: (next) => reference.write(next)(),
    update: (transition) => reference.modify(transition)(),
  };
}

export type IOState<State> = {
  readonly read: () => State;
  readonly replace: (next: State) => void;
  readonly update: (transition: (previous: State) => State) => void;
};

/** I/O境界で、保持中の値への参照を更新する。 */
export function createIOState<State>(state: State): IOState<State> {
  return {
    read: () => state,
    replace: (next) => {
      state = next;
    },
    update: (transition) => {
      state = transition(state);
    },
  };
}

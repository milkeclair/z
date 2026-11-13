type ScanContext<State> = {
  readonly state: State;
  readonly done: (state: State) => boolean;
  readonly step: (state: State) => State;
};

export function scan<State>({ state, done, step }: ScanContext<State>): State {
  let current = state;

  while (!done(current)) {
    current = step(current);
  }

  return current;
}

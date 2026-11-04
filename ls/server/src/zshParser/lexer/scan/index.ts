type ScanContext<State> = {
  readonly state: State;
  readonly done: (state: State) => boolean;
  readonly step: (state: State) => State;
};

export function scan<State>({ state, done, step }: ScanContext<State>): State {
  if (done(state)) {
    return state;
  } else {
    return scan({
      state: step(state),
      done,
      step,
    });
  }
}

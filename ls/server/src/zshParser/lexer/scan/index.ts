import { again, done, loop } from '../../../util/loop';

type ScanContext<State> = {
  readonly state: State;
  readonly done: (state: State) => boolean;
  readonly step: (state: State) => State;
};

export function scan<State>({ state, done: isComplete, step }: ScanContext<State>): State {
  return loop(state, (current) => (isComplete(current) ? done(current) : again(step(current))));
}

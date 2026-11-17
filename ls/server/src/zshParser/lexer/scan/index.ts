import { again, done as finish, loop } from '../../../util/loop';
type ScanContext<State> = {
  readonly state: State;
  readonly done: (state: State) => boolean;
  readonly step: (state: State) => State;
};
export function scan<State>({ state, done, step }: ScanContext<State>): State {
  return loop(state, (current) => (done(current) ? finish(current) : again(step(current))));
}

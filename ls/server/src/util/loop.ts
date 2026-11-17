import { tailRec } from 'fp-ts/ChainRec';
import { left, right, type Either } from 'fp-ts/Either';
export type LoopStep<State, Result> = Either<State, Result>;
export function loop<State, Result>(
  initial: State,
  step: (state: Readonly<State>) => LoopStep<State, Result>,
): Result {
  return tailRec(initial, (state) => step(state));
}
export function again<State>(state: State): LoopStep<State, never> {
  return left(state);
}
export function done<Result>(result: Result): LoopStep<never, Result> {
  return right(result);
}

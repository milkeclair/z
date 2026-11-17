export type LoopStep<State, Result> =
  | { readonly kind: 'continue'; readonly state: State }
  | { readonly kind: 'done'; readonly result: Result };

function run<State, Result>(
  current: LoopStep<State, Result>,
  step: (state: Readonly<State>) => LoopStep<State, Result>,
): Result {
  while (current.kind === 'continue') {
    current = step(current.state);
  }

  return current.result;
}

/** 各反復が返す次の値を、呼び出しスタックを増やさず処理する。 */
export function loop<State, Result>(
  initial: State,
  step: (state: Readonly<State>) => LoopStep<State, Result>,
): Result {
  return run<State, Result>(again(initial), step);
}

export function again<State>(state: State): LoopStep<State, never> {
  return { kind: 'continue', state };
}

export function done<Result>(result: Result): LoopStep<never, Result> {
  return { kind: 'done', result };
}

export type NestingState = { readonly depth: number; readonly limit: number };
export type NestingStep =
  | { readonly kind: 'enter'; readonly state: NestingState }
  | { readonly kind: 'limit'; readonly state: NestingState };

export const DefaultNestingLimit = 64;
export function enterNesting(state: NestingState): NestingStep {
  return state.depth >= state.limit ? { kind: 'limit', state }
    : { kind: 'enter', state: { ...state, depth: state.depth + 1 } };
}

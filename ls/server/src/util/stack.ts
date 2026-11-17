export type Stack<Value> = {
  readonly value: Value;
  readonly next: Stack<Value> | null;
};

export function pushStack<Value>(value: Value, next: Stack<Value> | null = null): Stack<Value> {
  return { value, next };
}

export function* stackValues<Value>(stack: Stack<Value> | null): Generator<Value> {
  while (stack) {
    yield stack.value;
    stack = stack.next;
  }
}

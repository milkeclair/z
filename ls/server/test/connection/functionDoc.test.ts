import { describe, expect, test } from 'vitest';
import { argumentDisplay, argumentType } from '../../src/connection/functionDoc';
import type { FuncArg } from '../../src/getFunctions/type';

const named: FuncArg = { name: 'behavior', position: -1, optional: true, isNamed: true };

describe('argumentType', () => {
  test('型の注記がない引数は通常の表示を保つ', () => {
    expect(argumentType(named)).toBe('');
  });

  test('code型と許可値を一つの注記として整形する', () => {
    expect(argumentType({ ...named, valueType: 'code' })).toBe('[code]');
    expect(argumentType({ ...named, valueType: 'code', literalValues: ['call_original', "a'b", 'a\\b'] }))
      .toBe("[code | 'call_original' | 'a\\'b' | 'a\\\\b']");
  });
});

describe('argumentDisplay', () => {
  test('引数の種類に合ったトークンへ型を併記する', () => {
    expect(argumentDisplay(named)).toBe('behavior=');
    expect(argumentDisplay({ ...named, valueType: 'code' })).toBe('behavior= [code]');
    expect(argumentDisplay({ name: 'command', position: 1, optional: false, isNamed: false, valueType: 'code' }))
      .toBe('$1 [code]');
  });
});

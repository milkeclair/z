import type { Result } from '../document/type';

export type FuncArg = {
  position: number;
  name: string;
  optional: boolean;
  isNamed: boolean;
  readonly valueType?: 'code';
  readonly literalValues?: readonly string[];
};

export type Func = {
  documentation?: Result;
  name: string;
  file: string;
  line: number;
  args: FuncArg[];
};

export type FuncContent = Omit<Func, 'file'>;

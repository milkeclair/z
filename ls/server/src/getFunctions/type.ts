import type { Result } from '../document/type';
import type { ClassReferenceType } from '../zshHydrator/documentation/types';

export type FuncArg = {
  readonly position: number;
  readonly name: string;
  readonly optional: boolean;
  readonly isNamed: boolean;
  readonly valueType?: 'code';
  readonly classReference?: ClassReferenceType;
  readonly literalValues?: readonly string[];
};

export type Func = {
  readonly documentation?: Result;
  readonly name: string;
  readonly file: string;
  readonly line: number;
  readonly args: readonly FuncArg[];
};

export type FuncContent = Omit<Func, 'file'>;

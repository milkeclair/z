export type Func = { name: string; file: string; line: number };
export type FuncContent = Omit<Func, 'file'>;

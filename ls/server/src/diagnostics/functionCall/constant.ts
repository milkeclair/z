export const OPERATORS = ['&&', '||', ';', '|', '>', '<', '>>'] as const;

export const TEST_DSL_FUNCTIONS = [
  'z.t.describe',
  'z.t.xdescribe',
  'z.t.context',
  'z.t.xcontext',
  'z.t.it',
  'z.t.xit',
  'z.group',
  'z.guard',
] as const;

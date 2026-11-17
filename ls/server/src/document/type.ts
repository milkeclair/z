export type Section = 'description' | 'parameters' | 'reply' | 'return' | 'example';

export type Result = {
  readonly description: string;
  readonly parameters: readonly {
    readonly name: string;
    readonly description: string;
  }[];
  readonly reply: string;
  readonly return: string;
  readonly example: string;
};

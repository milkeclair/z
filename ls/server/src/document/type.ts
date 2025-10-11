export type Section = 'description' | 'parameters' | 'reply' | 'return' | 'example';
export type Result = {
  description: string;
  parameters: { name: string; description: string }[];
  reply: string;
  return: string;
  example: string;
};

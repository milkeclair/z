import { Section } from './type';

export const sectionRegexes: Record<Section, RegExp> = {
  description: /.*?/,
  parameters: /^\$(\w+|@):/, // $1, $2..., $@, $arg:
  reply: /^REPLY:/,
  return: /^return:/,
  example: /^example:/,
};

export const sectionExtractRegexes: Record<Section, RegExp> = {
  description: /(.*)/,
  parameters: /^(\$(?:\w+|@)):\s*(.*)$/, // $1, $2..., $@, $arg:
  reply: /^REPLY:\s*(.*)$/,
  return: /^return:\s*(.*)$/,
  example: /(.*)/,
};

import { Section } from './type';

export const sectionRegexes: Record<Section, RegExp> = {
  description: /.*?/,
  parameters: /^\$(\d+|@):/, // $1, $2..., $@:
  reply: /^REPLY:/,
  return: /^return:/,
  example: /^example:/,
};

export const sectionExtractRegexes: Record<Section, RegExp> = {
  description: /(.*)/,
  parameters: /^(\$(?:\d+|@)):\s*(.*)$/, // $1, $2..., $@:
  reply: /^REPLY:\s*(.*)$/,
  return: /^return:\s*(.*)$/,
  example: /(.*)/,
};

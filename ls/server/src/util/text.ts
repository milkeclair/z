import { again, done, loop } from './loop';

export function textWhileEnd(
  text: string,
  start: number,
  predicate: (char: string) => boolean,
): number {
  return loop(start, (index) =>
    index < text.length && predicate(text[index]) ? again(index + 1) : done(index),
  );
}

export function horizontalWhitespaceEnd(text: string, start: number): number {
  return textWhileEnd(text, start, (char) => char === ' ' || char === '\t');
}

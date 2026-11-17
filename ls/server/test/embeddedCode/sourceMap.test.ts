import { describe, expect, test } from 'vitest';
import { createZshFileHydration } from '../../src/zshHydrator';
import { findAll } from '../../src/zshParser/ast';
import { decodeLiteral, literalValue } from '../../src/embeddedCode/literal';
import { createCodeSourceMap, codeRange, codeOffset, codeRanges, textLineStarts, textPosition } from '../../src/embeddedCode/sourceMap';

describe('embedded source map composition', () => {
  test('複数段の引用を平坦なmapへ合成する', () => {
    const quote = (value: string) => "'" + value.split("'").join("'\\''") + "'";
    let text = 'missing-command';
    for (let level = 0; level < 4; level++) text = 'run code=' + quote(text);
    const physical = 'print 😀;\r\n' + text + '\r\n';
    let file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: physical });
    let source: ReturnType<typeof createCodeSourceMap> | undefined;
    for (let level = 0; level < 4; level++) {
      const call = findAll(file.ast, 'simpleCommand').find(command => command.commandName?.word.raw === 'run');
      if (!call) throw new Error('run expected');
      const word = call.arguments[0];
      const decoded = decodeLiteral(word);
      if (!decoded) throw new Error('literal expected');
      const value = literalValue(decoded, 5);
      source = createCodeSourceMap(word, value, source);
      file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: value.text });
    }
    if (!source) throw new Error('source map expected');
    const command = findAll(file.ast, 'simpleCommand')[0];
    const range = codeRange(source, command.range);
    expect(physical.slice(range.start.offset, range.end.offset)).toBe('missing-command');
    expect(range.start.line).toBe(1);
    expect(source.spans).toHaveLength('missing-command'.length);
  });
});

test('空の値・未完引用符とescape途中のカーソルを区別する', () => {
  for (const raw of ["code=''", "code='"]) {
    const content = 'run ' + raw;
    const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
    const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
    const decoded = decodeLiteral(word, true);
    if (!decoded) throw new Error('literal required');
    const source = createCodeSourceMap(word, literalValue(decoded, 5));
    const point = content.indexOf("'") + 1;
    expect(codeOffset(source, point)).toBe(0);
    expect(codeRange(source, { start: { offset: 0, line: 0, character: 0 }, end: { offset: 0, line: 0, character: 0 } })
      .start.offset).toBe(point);
  }
  const content = "run code=$'\\x67reet'";
  const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
  const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
  const decoded = decodeLiteral(word);
  if (!decoded) throw new Error('literal required');
  const source = createCodeSourceMap(word, literalValue(decoded, 5));
  const start = content.indexOf('\\x67');
  expect(codeOffset(source, start)).toBe(0);
  expect(codeOffset(source, start + 2)).toBeNull();
  expect(codeOffset(source, start + 4)).toBe(1);
});

test('引用の接続部分を色分けの範囲へ含めず、上限で断片数を抑える', () => {
  const content = "run code='gr'e'et'";
  const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
  const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
  const decoded = decodeLiteral(word);
  if (!decoded) throw new Error('literal required');
  const source = createCodeSourceMap(word, literalValue(decoded, 5));
  const range = { start: { offset: 0, line: 0, character: 0 }, end: { offset: 5, line: 0, character: 5 } };
  const ranges = codeRanges(source, range);
  expect(ranges.map(range => content.slice(range.start.offset, range.end.offset))).toEqual(['gr', 'e', 'et']);
  expect(codeRanges(source, range, 2)).toHaveLength(2);
  expect(codeRanges(source, range, 0)).toEqual([]);
});

test('CRLF・単独CR・絵文字の行位置をUTF-16で求める', () => {
  const text = '😀\r\nx\ry\nz';
  const starts = textLineStarts(text);
  expect(starts).toEqual([0, 4, 6, 8]);
  expect(textPosition(starts, 4)).toEqual({ offset: 4, line: 1, character: 0 });
  expect(textPosition(starts, 9)).toEqual({ offset: 9, line: 3, character: 1 });
});

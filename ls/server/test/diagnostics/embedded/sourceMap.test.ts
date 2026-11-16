import { describe, expect, test } from 'vitest';
import { createZshFileHydration } from '../../../src/zshHydrator';
import { findAll } from '../../../src/zshParser/ast';
import { decodeLiteral, literalValue } from '../../../src/diagnostics/embedded/literal';
import { createCodeSourceMap, codeRange } from '../../../src/diagnostics/embedded/sourceMap';

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

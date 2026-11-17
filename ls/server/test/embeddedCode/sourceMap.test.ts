import { numberRange } from '../../src/util/collections';
import { describe, expect, test } from 'vitest';
import { decodeLiteral, literalValue } from '../../src/embeddedCode/literal';
import {
  codeOffset,
  codeRange,
  codeRanges,
  createCodeSourceMap,
  textLineStarts,
  textPosition,
} from '../../src/embeddedCode/sourceMap';
import { createZshFileHydration } from '../../src/zshHydrator';
import { findAll } from '../../src/zshParser/ast';

describe('createCodeSourceMap', () => {
  describe('内側のコードを元の位置へ対応付ける場合', () => {
    test('複数段の引用を平坦なmapへ合成する', () => {
      const quote = (value: string) => "'" + value.split("'").join("'\\''") + "'";
      const text = numberRange(0, 4).reduce((text) => 'run code=' + quote(text), 'missing-command');
      const physical = 'print 😀;\r\n' + text + '\r\n';

      type Layer = {
        readonly file: ReturnType<typeof createZshFileHydration>;
        readonly source: ReturnType<typeof createCodeSourceMap> | undefined;
      };

      const initial: Layer = {
        file: createZshFileHydration({ sourceFile: 'x', file: 'x', content: physical }),
        source: undefined,
      };
      const { file, source } = numberRange(0, 4).reduce<Layer>((previous) => {
        const call = findAll(previous.file.ast, 'simpleCommand').find(
          (command) => command.commandName?.word.raw === 'run',
        );

        if (!call) {
          throw new Error('run expected');
        }

        const word = call.arguments[0];
        const decoded = decodeLiteral(word);

        if (!decoded) {
          throw new Error('literal expected');
        }

        const value = literalValue(decoded, 5);

        return {
          source: createCodeSourceMap(word, value, previous.source),
          file: createZshFileHydration({ sourceFile: 'x', file: 'x', content: value.text }),
        };
      }, initial);

      if (!source) {
        throw new Error('source map expected');
      }

      const command = findAll(file.ast, 'simpleCommand')[0];
      const range = codeRange(source, command.range);

      expect(physical.slice(range.start.offset, range.end.offset)).toBe('missing-command');
      expect(range.start.line).toBe(1);
      expect(source.spans).toHaveLength('missing-command'.length);
    });
  });
});

describe('textPosition', () => {
  describe('改行方式とUTF-16の位置を対応付ける場合', () => {
    test('CRLF・単独CR・絵文字の行位置をUTF-16で求める', () => {
      const text = '😀\r\nx\ry\nz';
      const starts = textLineStarts(text);

      expect(starts).toEqual([0, 4, 6, 8]);
      expect(textPosition(starts, 4)).toEqual({ offset: 4, line: 1, character: 0 });
      expect(textPosition(starts, 9)).toEqual({ offset: 9, line: 3, character: 1 });
    });
  });
});

describe('codeRanges', () => {
  describe('引用部分を物理的な範囲へ分ける場合', () => {
    test('引用の接続部分を色分けの範囲へ含めず、上限で断片数を抑える', () => {
      const content = "run code='gr'e'et'";
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
      const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
      const decoded = decodeLiteral(word);

      if (!decoded) {
        throw new Error('literal required');
      }

      const source = createCodeSourceMap(word, literalValue(decoded, 5));
      const range = {
        start: { offset: 0, line: 0, character: 0 },
        end: { offset: 5, line: 0, character: 5 },
      };
      const ranges = codeRanges(source, range);

      expect(ranges.map((range) => content.slice(range.start.offset, range.end.offset))).toEqual([
        'gr',
        'e',
        'et',
      ]);
      expect(codeRanges(source, range, 2)).toHaveLength(2);
      expect(codeRanges(source, range, 0)).toEqual([]);
    });
  });
});

describe('codeOffset', () => {
  describe('空の引用とエスケープ中の位置を区別する場合', () => {
    test('空の値・未完引用符とescape途中のカーソルを区別する', () => {
      for (const raw of ["code=''", "code='"]) {
        const content = 'run ' + raw;
        const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
        const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
        const decoded = decodeLiteral(word, true);

        if (!decoded) {
          throw new Error('literal required');
        }

        const source = createCodeSourceMap(word, literalValue(decoded, 5));
        const point = content.indexOf("'") + 1;

        expect(codeOffset(source, point)).toBe(0);
        expect(
          codeRange(source, {
            start: { offset: 0, line: 0, character: 0 },
            end: { offset: 0, line: 0, character: 0 },
          }).start.offset,
        ).toBe(point);
      }

      const content = "run code=$'\\x67reet'";
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content });
      const word = findAll(file.ast, 'simpleCommand')[0].arguments[0];
      const decoded = decodeLiteral(word);

      if (!decoded) {
        throw new Error('literal required');
      }

      const source = createCodeSourceMap(word, literalValue(decoded, 5));
      const start = content.indexOf('\\x67');

      expect(codeOffset(source, start)).toBe(0);
      expect(codeOffset(source, start + 2)).toBeNull();
      expect(codeOffset(source, start + 4)).toBe(1);
    });
  });
});

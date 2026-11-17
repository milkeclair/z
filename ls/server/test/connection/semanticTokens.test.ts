import { List, Range } from 'immutable';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { codeTokenTypes, zSemanticTokens } from '../../src/connection/semanticTokens';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();
afterEach(() => {
  temporaryDirectories.cleanup();
});

function rawTokens(content: string) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-colors-'));
  temporaryDirectories.track(root);
  fs.writeFileSync(
    path.join(root, 'definition.zsh'),
    "# $code [code | 'noop']: commands\nrun_code() { : }\n",
  );
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: emptyShellEnvironment() });
  const programs = diagnostics.files.get(document.uri)?.codePrograms ?? [];
  return { document, result: zSemanticTokens({ document, programs }) };
}

function tokens(content: string) {
  const { document, result } = rawTokens(content);
  type Decoded = {
    readonly text: string;
    readonly type: string;
    readonly line: number;
    readonly start: number;
    readonly end: number;
  };
  return Range(0, result.data.length, 5)
    .reduce(
      (previous, index) => {
        const line = previous.line + result.data[index];
        const character = result.data[index]
          ? result.data[index + 1]
          : previous.character + result.data[index + 1];
        const length = result.data[index + 2],
          last = previous.tokens.last();
        expect(length).toBeGreaterThan(0);
        if (last?.line === line) {
          expect(character).toBeGreaterThanOrEqual(last.end);
        }
        return {
          line,
          character,
          tokens: previous.tokens.push({
            text: document.getText({
              start: { line, character },
              end: { line, character: character + length },
            }),
            type: codeTokenTypes[result.data[index + 3]],
            line,
            start: character,
            end: character + length,
          }),
        };
      },
      { line: 0, character: 0, tokens: List<Decoded>() },
    )
    .tokens.toArray();
}

describe('semantic tokens for code arguments', () => {
  test('コード内の構文要素を分類し、外側の文字列には適用しない', () => {
    const result = tokens('run_code code=\'if true; then greet "$value" 123; # example\nfi\'\n');
    expect(result).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ text: 'if', type: 'keyword' }),
        expect.objectContaining({ text: 'greet', type: 'function' }),
        expect.objectContaining({ text: '$value', type: 'variable' }),
        expect.objectContaining({ text: '123', type: 'number' }),
        expect.objectContaining({ text: '# example', type: 'comment' }),
      ]),
    );
    expect(
      result.some((token) => token.text.includes('run_code') || token.text.includes('code=')),
    ).toBe(false);
  });

  test('通常の引数にある予約語風の文字列をキーワードにしない', () => {
    expect(tokens("run_code code='print if'\n")).toEqual(
      expect.arrayContaining([expect.objectContaining({ text: 'if', type: 'parameter' })]),
    );
  });

  test('CRLF・日本語・入れ子・ANSI escapeでも物理的なUTF-16位置へ返す', () => {
    const source = 'print 日本😀;\r\nrun_code code="run_code code=\'greet value\'"\r\n';
    const result = tokens(source);
    const greet = result.find((token) => token.text === 'greet' && token.type === 'function');
    expect(greet).toMatchObject({ line: 1, start: source.split('\r\n')[1].indexOf('greet') });
    expect(tokens(String.raw`run_code code=$'\x67reet value'` + '\n')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ text: String.raw`\x67reet`, type: 'function' }),
      ]),
    );
  });

  test.each(["print 'greet'\n", "run_code code='noop'\n", 'run_code code="$value"\n'])(
    '未注釈・許可値・動的な文字列は通常表示へ任せる: %s',
    (source) => {
      expect(tokens(source)).toEqual([]);
    },
  );
});

test('深いコマンド置換でも色分けを有界に返す', () => {
  const code = Range(0, 1000).reduce((code) => 'print "$(' + code + ')"', 'greet value');
  const result = tokens("run_code code='" + code + "'\n");
  expect(result.length).toBeGreaterThan(0);
  expect(result.length).toBeLessThan(code.length);
});

test('大量の物理行にまたがる文字列でも出力token数を抑える', () => {
  const lines = 'a\n'.repeat(50000);
  const { result } = rawTokens('run_code code=\'print "' + lines + '"\'\n');
  expect(result.data.length).toBeGreaterThan(0);
  expect(result.data.length).toBeLessThan(50000 * 5);
});

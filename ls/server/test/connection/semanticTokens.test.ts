import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { zSemanticTokens, codeTokenTypes } from '../../src/connection/semanticTokens';

const roots: string[] = [];
afterEach(() => { for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true }); });

function rawTokens(content: string) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-colors-')); roots.push(root);
  fs.writeFileSync(path.join(root, 'definition.zsh'), "# $code [code | 'noop']: commands\nrun_code() { : }\n");
  const document = TextDocument.create(pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, content);
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: emptyShellEnvironment() });
  const programs = diagnostics.files.get(document.uri)?.codePrograms ?? [];
  return { document, result: zSemanticTokens({ document, programs }) };
}

function tokens(content: string) {
  const { document, result } = rawTokens(content);
  const decoded: { text: string; type: string; line: number; start: number; end: number }[] = [];
  let line = 0; let character = 0;
  for (let i = 0; i < result.data.length; i += 5) {
    line += result.data[i];
    character = result.data[i] ? result.data[i + 1] : character + result.data[i + 1];
    const length = result.data[i + 2];
    const previous = decoded.at(-1);
    expect(length).toBeGreaterThan(0);
    if (previous?.line === line) expect(character).toBeGreaterThanOrEqual(previous.end);
    decoded.push({ text: document.getText({ start: { line, character }, end: { line, character: character + length } }),
      type: codeTokenTypes[result.data[i + 3]], line, start: character, end: character + length });
  }
  return decoded;
}

describe('semantic tokens for code arguments', () => {
  test('コード内の構文要素を分類し、外側の文字列には適用しない', () => {
    const result = tokens("run_code code='if true; then greet \"$value\" 123; # example\nfi'\n");
    expect(result).toEqual(expect.arrayContaining([
      expect.objectContaining({ text: 'if', type: 'keyword' }),
      expect.objectContaining({ text: 'greet', type: 'function' }),
      expect.objectContaining({ text: '$value', type: 'variable' }),
      expect.objectContaining({ text: '123', type: 'number' }),
      expect.objectContaining({ text: '# example', type: 'comment' }),
    ]));
    expect(result.some(token => token.text.includes('run_code') || token.text.includes('code='))).toBe(false);
  });

  test('通常の引数にある予約語風の文字列をキーワードにしない', () => {
    expect(tokens("run_code code='print if'\n")).toEqual(expect.arrayContaining([
      expect.objectContaining({ text: 'if', type: 'parameter' }),
    ]));
  });

  test('CRLF・日本語・入れ子・ANSI escapeでも物理的なUTF-16位置へ返す', () => {
    const source = 'print 日本😀;\r\nrun_code code="run_code code=\'greet value\'"\r\n';
    const result = tokens(source);
    const greet = result.find(token => token.text === 'greet' && token.type === 'function');
    expect(greet).toMatchObject({ line: 1, start: source.split('\r\n')[1].indexOf('greet') });
    expect(tokens(String.raw`run_code code=$'\x67reet value'` + '\n'))
      .toEqual(expect.arrayContaining([expect.objectContaining({ text: String.raw`\x67reet`, type: 'function' })]));
  });

  test.each(["print 'greet'\n", "run_code code='noop'\n", 'run_code code="$value"\n'])(
    '未注釈・許可値・動的な文字列は通常表示へ任せる: %s', source => {
      expect(tokens(source)).toEqual([]);
    },
  );
});

test('深いコマンド置換でも色分けを有界に返す', () => {
  let code = 'greet value';
  for (let i = 0; i < 1000; i++) code = 'print "$(' + code + ')"';
  const result = tokens("run_code code='" + code + "'\n");
  expect(result.length).toBeGreaterThan(0);
  expect(result.length).toBeLessThan(code.length);
});

test('大量の物理行にまたがる文字列でも出力token数を抑える', () => {
  const lines = 'a\n'.repeat(50000);
  const { result } = rawTokens("run_code code='print \"" + lines + "\"'\n");
  expect(result.data.length).toBeGreaterThan(0);
  expect(result.data.length).toBeLessThan(50000 * 5);
});

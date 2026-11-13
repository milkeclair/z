import { afterEach, describe, expect, test, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { Lexer } from '../../src/zshParser/lexer';
import { refreshFunctions, refreshFunctionSnapshot, createFunctionSnapshot } from '../../src/refreshFunctions/main';

const roots: string[] = [];
function fixture(): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-function-snapshot-'));
  roots.push(root);
  return root;
}
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
function document(root: string, file: string, version: number, content: string) {
  return TextDocument.create(pathToFileURL(path.join(root, file)).href, 'shellscript', version, content);
}

describe('refreshFunctionSnapshot', () => {

  test('呼び出し側だけの編集では関数情報の投影を再利用する', () => {
    const root = fixture();
    fs.writeFileSync(path.join(root, 'functions.zsh'), 'helper() { : }\n');
    const first = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
    const next = refreshFunctionSnapshot({ previous: first, projectRoot: root,
      documents: [document(root, 'caller.zsh', 1, 'helper x\n')] });
    expect(next).not.toBe(first);
    expect(next.hydrator.files.has('caller.zsh')).toBe(true);
    expect(next.functions).toBe(first.functions);
    expect(first.hydrator.files.has('caller.zsh')).toBe(false);
  });

  test('一般名・入れ子・function形式をASTから互換ビューへ変換する', () => {
    const root = fixture();
    fs.writeFileSync(path.join(root, 'sample.zsh'), [
      '# $2?: second', '# $1: first', '# $@: tail', '# $one: option one', '# $two?: option two',
      'greet() { inner() { : } }', 'function alternative', '{ : }', '',
    ].join('\n'));
    const result = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
    expect(result.functions.map(fn => [fn.name, fn.line])).toEqual([
      ['greet', 6], ['inner', 6], ['alternative', 7],
    ]);
    expect(result.functions[0]).toMatchObject({
      name: 'greet', file: 'sample.zsh', line: 6, args: [
        { position: 1, name: 'first', optional: false, isNamed: false },
        { position: 2, name: 'second', optional: true, isNamed: false },
        { position: Number.MAX_SAFE_INTEGER, name: '@', optional: false, isNamed: false },
        { position: -1, name: 'two', optional: true, isNamed: true },
        { position: -1, name: 'one', optional: false, isNamed: true },
      ],
    });
    expect(result.functions[0].documentation?.parameters).toEqual([
      { name: '$2', description: 'second' }, { name: '$1', description: 'first' },
      { name: '$@', description: 'tail' }, { name: '$one', description: 'option one' },
      { name: '$two', description: 'option two' },
    ]);
    expect(refreshFunctions({ projectRoot: root, documents: [] })).toEqual(result.functions);
  });

  test('例示中の引数タグを互換引数へ混ぜない', () => {
    const root = fixture();
    const result = refreshFunctionSnapshot({ projectRoot: root, documents: [
      document(root, 'new.zsh', 1, '# $1: real\n# example:\n#   $2: example\nhelper() { : }\n'),
    ] });
    expect(result.functions[0].args).toEqual([
      { position: 1, name: 'real', optional: false, isNamed: false },
    ]);
  });

  test('編集したbufferだけを再解析し、変更のないsnapshotと互換ビューを再利用する', () => {
    const root = fixture();
    fs.writeFileSync(path.join(root, 'a.zsh'), 'first() { : }\n');
    fs.writeFileSync(path.join(root, 'b.zsh'), 'second() { : }\n');
    const first = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
    const spy = vi.spyOn(Lexer, 'tokenize');
    expect(refreshFunctionSnapshot({ previous: first, projectRoot: root, documents: [] })).toBe(first);
    expect(spy).not.toHaveBeenCalled();
    const changed = refreshFunctionSnapshot({ previous: first, projectRoot: root,
      documents: [document(root, 'a.zsh', 1, 'edited() { : }\n')] });
    expect(spy).toHaveBeenCalledTimes(1);
    expect(changed.hydrator.files.get('b.zsh')).toBe(first.hydrator.files.get('b.zsh'));
    expect(changed.functions.map(fn => fn.name)).toEqual(['edited', 'second']);
    expect(first.functions.map(fn => fn.name)).toEqual(['first', 'second']);
  });

  test('保存・close・disk削除と文書の開き直しを反映する', () => {
    const root = fixture();
    const file = path.join(root, 'sample.zsh');
    fs.writeFileSync(file, 'disk() { : }\n');
    const first = refreshFunctionSnapshot({ projectRoot: root, documents: [
      document(root, 'sample.zsh', 1, 'live() { : }\n'),
    ] });
    fs.writeFileSync(file, 'saved() { : }\n');
    const saved = refreshFunctionSnapshot({ previous: first, projectRoot: root, documents: [
      document(root, 'sample.zsh', 2, 'saved() { : }\n'),
    ] });
    const closed = refreshFunctionSnapshot({ previous: saved, projectRoot: root, documents: [] });
    expect(closed.functions[0].name).toBe('saved');
    const reopened = refreshFunctionSnapshot({ previous: closed, projectRoot: root, documents: [
      document(root, 'sample.zsh', 1, 'other() { : }\n'),
    ] });
    expect(reopened.functions[0].name).toBe('other');
    fs.unlinkSync(file);
    expect(refreshFunctionSnapshot({ previous: reopened, projectRoot: root, documents: [] }).functions).toEqual([]);
    expect(first.functions[0].name).toBe('live');
  });

  test('workspace外・非file URI・対象外拡張子を追加しない', () => {
    const root = fixture();
    const result = refreshFunctionSnapshot({ projectRoot: root, documents: [
      document(path.dirname(root), 'outside.zsh', 1, 'outside() { : }\n'),
      document(root, 'ignored.txt', 1, 'ignored() { : }\n'),
      TextDocument.create('untitled:new.zsh', 'shellscript', 1, 'untitled() { : }\n'),
    ] });
    expect(result.functions).toEqual([]);
  });

  test('空の互換ビューを別の接続と共有しない', () => {
    const first = createFunctionSnapshot();
    const second = createFunctionSnapshot();
    expect(first.functions).not.toBe(second.functions);
    expect(first.hydrator.files.size).toBe(0);
  });
  test('文書ASTと関数索引は同じhydrationを参照し、呼び出し編集では索引を再利用する', () => {
    const root = fixture();
    const definition = document(root, 'definitions.zsh', 1, 'helper() { : }\n');
    const caller = document(root, 'caller.zsh', 1, 'helper x\n');
    const first = refreshFunctionSnapshot({ projectRoot: root, documents: [definition, caller] });
    const file = first.hydrator.files.get('definitions.zsh');
    expect(first.documents.get(definition.uri)?.file).toBe(file);
    expect(first.targets.get('helper')?.[0].definition).toBe(file?.functions[0].definition);
    const spy = vi.spyOn(Lexer, 'tokenize');
    const next = refreshFunctionSnapshot({ previous: first, projectRoot: root,
      documents: [definition, document(root, 'caller.zsh', 2, 'helper y\n')] });
    expect(spy).toHaveBeenCalledTimes(1);
    expect(next.targets).toBe(first.targets);
    expect(next.documents.get(definition.uri)).toBe(first.documents.get(definition.uri));
  });

  test('workspace外の開いた文書は探索用に保持し、候補へ混ぜず、close時に解放する', () => {
    const root = fixture();
    const external = document(path.dirname(root), 'external.zsh', 1, 'external() { : }\n');
    const first = refreshFunctionSnapshot({ projectRoot: root, documents: [external] });
    expect(first.targets.size).toBe(0);
    expect(first.hydrator.files.size).toBe(0);
    expect(first.documents.get(external.uri)?.file.functions[0].name).toBe('external');
    const spy = vi.spyOn(Lexer, 'tokenize');
    const same = refreshFunctionSnapshot({ previous: first, projectRoot: root, documents: [external] });
    expect(same).toBe(first);
    expect(spy).not.toHaveBeenCalled();
    const closed = refreshFunctionSnapshot({ previous: same, projectRoot: root, documents: [] });
    expect(closed.documents.size).toBe(0);
    expect(first.documents.size).toBe(1);
  });

});

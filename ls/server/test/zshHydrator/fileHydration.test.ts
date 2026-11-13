import { describe, expect, test } from 'vitest';
import { findAll, locate } from '../../src/zshParser/ast';
import { createZshFileHydration, documentationOf, directivesOf, hydrateAst } from '../../src/zshHydrator';

describe('zshHydrator@file', () => {
  test('タブで区切った引数コメントを元の範囲とともに付加する', () => {
    const source = '#\t$1: positional\n# $name?\t:\tnamed\nhelper() { : }\n';
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: source });
    const documentation = documentationOf(result.functions[0].definition);
    expect(result.hydrationDiagnostics).toEqual([]);
    expect(documentation?.parameters).toMatchObject([
      { kind: 'positionalParameterDoc', position: 1, description: 'positional' },
      { kind: 'namedParameterDoc', name: 'name', optional: true, description: 'named' },
    ]);
    for (const parameter of documentation?.parameters ?? []) {
      expect(source.slice(parameter.markerRange.start.offset, parameter.markerRange.end.offset)).toBe(
        parameter.kind === 'positionalParameterDoc' ? '$1' : '$name',
      );
    }
  });

  test.each(['#\tzls:\tignore\trule\tother', '# zls:\tignore\trule\tother'])(
    'タブ区切りの制御コメントを単語と範囲へ分解する: %j', (comment) => {
      const source = comment + '\nhelper() { : }\n';
      const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: source });
      const directives = result.ast.comments.flatMap(directivesOf);
      expect(directives).toMatchObject([{ namespace: 'zls', command: 'ignore',
        arguments: [{ value: 'rule', raw: 'rule' }, { value: 'other', raw: 'other' }] }]);
      for (const argument of directives[0]?.arguments ?? []) {
        expect(source.slice(argument.range.start.offset, argument.range.end.offset)).toBe(argument.raw);
      }
    },
  );

  test('example内のインデントした見出しから節を切り替えない', () => {
    const source = ['# example:', '#   REPLY: example output', '#   $1: example argument',
      '#   zls: ignore example', 'helper() { : }'].join('\n');
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: source });
    const documentation = documentationOf(result.functions[0].definition);
    expect(documentation?.parameters).toEqual([]);
    expect(documentation?.reply).toBeNull();
    expect(documentation?.examples[0].text).toContain('REPLY: example output');
    expect(result.ast.comments.flatMap(directivesOf)).toEqual([]);
  });

  test('制御コメントを付加しても構文診断を抑制しない', () => {
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: 'helper() { # zls: ignore\n' });
    expect(result.parserDiagnostics.map((item) => item.kind)).toEqual(['missingClosingBrace']);
    expect(result.ast.comments.map(directivesOf).flat()).toHaveLength(1);
  });

  test('全関数名の定義を同じASTへの参照として保持する', () => {
    const result = createZshFileHydration({ sourceFile: '/project/sample.zsh', file: 'sample.zsh', content: [
      '# helper description', '# $1: file path', '# $verbose?: verbose mode', '# $@: remaining arguments',
      '# REPLY: result', '# return: 0|1', '# example:', '#  helper x', '# $2: example only', '# zls: ignore example',
      'helper() { echo "$1" }', '# zls: ignore real', 'if true; then other() { : }; fi', '',
    ].join('\n') });
    expect(result.lexerDiagnostics).toEqual([]);
    expect(result.parserDiagnostics).toEqual([]);
    expect(result.hydrationDiagnostics).toEqual([]);
    const definitions = findAll(result.ast, 'functionDefinition');
    expect(result.functions.map((fn) => fn.name)).toEqual(['helper', 'other']);
    expect(result.functions[0].definition).toBe(definitions[0]);
    expect(result.functions[1].definition).toBe(definitions[1]);
    const documentation = documentationOf(definitions[0]);
    expect(documentation?.parameters).toMatchObject([
      { kind: 'positionalParameterDoc', position: 1, description: 'file path', optional: false },
      { kind: 'namedParameterDoc', name: 'verbose', description: 'verbose mode', optional: true },
      { kind: 'restParameterDoc', parameter: '@', description: 'remaining arguments', optional: false },
    ]);
    expect(documentation?.reply?.text).toBe('result');
    expect(documentation?.returns?.text).toBe('0|1');
    expect(documentation?.examples[0].text).toContain('$2: example only');
    const comments = result.ast.comments;
    const example = comments.find((comment) => comment.text.includes('ignore example'));
    const real = comments.find((comment) => comment.text.includes('ignore real'));
    expect(example && directivesOf(example)).toEqual([]);
    expect(real && directivesOf(real)).toMatchObject([{ namespace: 'zls', command: 'ignore', arguments: [{ value: 'real' }] }]);
    const first = definitions[0].leadingDoc?.comments[0];
    expect(first).toBe(comments[0]);
    const location = locate(result.query, comments[0].range.start.offset + 2);
    expect(location).toMatchObject({ kind: 'comment', target: definitions[0] });
  });

  test('再ハイドレーションで付加情報を重複させず入力ASTを変更しない', () => {
    const source = '# $1: value\nhelper() { : } # zls: ignore\n';
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: source });
    const again = hydrateAst(result.ast, source);
    expect(documentationOf(findAll(again, 'functionDefinition')[0])?.parameters).toHaveLength(1);
    expect(again).toEqual(result.ast);
    const configured = hydrateAst(result.ast, source, { directiveNamespaces: ['custom'] });
    expect(configured.comments.map(directivesOf).flat()).toEqual([]);
    expect(result.ast.comments.map(directivesOf).flat()).toHaveLength(1);
  });

  test('文書の不完全な引数タグは構文診断と区別する', () => {
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x', content: '# $name? missing colon\nhelper() { : }\n' });
    expect(result.parserDiagnostics).toEqual([]);
    expect(result.hydrationDiagnostics).toMatchObject([{ kind: 'invalidParameterDoc' }]);
  });

  test('登録したnamespaceだけを実コメントから解釈する', () => {
    const result = createZshFileHydration({ sourceFile: 'x', file: 'x',
      content: 'echo "# custom: ignore string"\n# prose custom: ignore\n# custom: ignore rule\n',
      options: { directiveNamespaces: ['custom'] } });
    expect(result.ast.comments.map(directivesOf).flat()).toMatchObject([{ namespace: 'custom', command: 'ignore', arguments: [{ value: 'rule' }] }]);
  });
});

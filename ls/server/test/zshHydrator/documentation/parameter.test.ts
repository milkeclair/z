import { describe, expect, test } from 'vitest';
import { createZshFileHydration, documentationOf } from '../../../src/zshHydrator';

function hydrate(comment: string) {
  const content = comment + '\nhelper() { : }\n';
  const file = createZshFileHydration({
    sourceFile: 'parameters.zsh',
    file: 'parameters.zsh',
    content,
  });
  return { content, file, documentation: documentationOf(file.functions[0].definition) };
}

describe('code parameter documentation', () => {
  test.each([
    ['# $behavior? [code]: commands to execute', 'namedParameterDoc', true],
    ['# $1 [code]: commands to execute', 'positionalParameterDoc', false],
    ['# $@? [code]: commands to execute', 'restParameterDoc', true],
    ['# $behavior?\t[code]\t:\tcommands to execute', 'namedParameterDoc', true],
  ])('型を引数ドキュメントへ付加する: %s', (comment, kind, optional) => {
    const result = hydrate(comment);
    expect(result.file.hydrationDiagnostics).toEqual([]);
    expect(result.documentation?.parameters).toMatchObject([
      { kind, optional, valueType: 'code', description: 'commands to execute' },
    ]);
    const parameter = result.documentation?.parameters[0];
    expect(
      parameter && result.content.slice(parameter.range.start.offset, parameter.range.end.offset),
    ).toBe(comment);
  });

  test('codeと許可する文字列のunionを保持する', () => {
    const result = hydrate(
      '# $behavior? [code | \'call_original\' | "disabled"]: commands to execute',
    );
    expect(result.file.hydrationDiagnostics).toEqual([]);
    expect(result.documentation?.parameters[0]).toMatchObject({
      valueType: 'code',
      literalValues: ['call_original', 'disabled'],
    });
  });

  test.each(['# $code [code | unquoted]: commands', "# $code [code | 'unfinished]: commands"])(
    '不完全な許可値を文書診断として返す: %s',
    (comment) => {
      expect(hydrate(comment).file.hydrationDiagnostics).toMatchObject([
        { kind: 'invalidParameterDoc' },
      ]);
    },
  );

  test('通常の説明文へ型を追加しない', () => {
    const result = hydrate('# $text?: [code] is ordinary description text');
    expect(result.file.hydrationDiagnostics).toEqual([]);
    expect(result.documentation?.parameters[0]).not.toHaveProperty('valueType');
    expect(result.documentation?.parameters[0].description).toBe(
      '[code] is ordinary description text',
    );
  });

  test.each(['# $code [unknown]: commands', '# $code [code commands', '# $code [code] commands'])(
    '不完全な型宣言を文書診断として返す: %s',
    (comment) => {
      const result = hydrate(comment);
      expect(result.file.parserDiagnostics).toEqual([]);
      expect(result.file.hydrationDiagnostics).toMatchObject([{ kind: 'invalidParameterDoc' }]);
    },
  );

  test('example内の型宣言を引数へ混ぜない', () => {
    const result = hydrate('# example:\n#   $code [code]: example only');
    expect(result.documentation?.parameters).toEqual([]);
    expect(result.documentation?.examples[0].text).toContain('[code]');
  });
});

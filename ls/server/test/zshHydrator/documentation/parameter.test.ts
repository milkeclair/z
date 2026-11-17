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

describe('parseFunctionDocumentation', () => {
  describe('引数の型アノテーションを読む場合', () => {
    test('名前付き引数にcode型と任意指定を付加する', () => {
      const comment = '# $behavior? [code]: commands to execute';
      const kind = 'namedParameterDoc';
      const optional = true;

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

    test('位置引数にcode型を付加する', () => {
      const comment = '# $1 [code]: commands to execute';
      const kind = 'positionalParameterDoc';
      const optional = false;

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

    test('可変長引数にcode型と任意指定を付加する', () => {
      const comment = '# $@? [code]: commands to execute';
      const kind = 'restParameterDoc';
      const optional = true;

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

    test('タブ区切りの宣言にもcode型を付加する', () => {
      const comment = '# $behavior?\t[code]\t:\tcommands to execute';
      const kind = 'namedParameterDoc';
      const optional = true;

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

    test('引用されていない許可値を文書診断にする', () => {
      const comment = '# $code [code | unquoted]: commands';

      expect(hydrate(comment).file.hydrationDiagnostics).toMatchObject([
        { kind: 'invalidParameterDoc' },
      ]);
    });

    test('閉じていない許可値を文書診断にする', () => {
      const comment = "# $code [code | 'unfinished]: commands";

      expect(hydrate(comment).file.hydrationDiagnostics).toMatchObject([
        { kind: 'invalidParameterDoc' },
      ]);
    });

    test('通常の説明文へ型を追加しない', () => {
      const result = hydrate('# $text?: [code] is ordinary description text');

      expect(result.file.hydrationDiagnostics).toEqual([]);
      expect(result.documentation?.parameters[0]).not.toHaveProperty('valueType');
      expect(result.documentation?.parameters[0].description).toBe(
        '[code] is ordinary description text',
      );
    });

    test('未対応の型を文書診断にする', () => {
      const comment = '# $code [unknown]: commands';

      const result = hydrate(comment);

      expect(result.file.parserDiagnostics).toEqual([]);
      expect(result.file.hydrationDiagnostics).toMatchObject([{ kind: 'invalidParameterDoc' }]);
    });

    test('閉じ角括弧のない型を文書診断にする', () => {
      const comment = '# $code [code commands';

      const result = hydrate(comment);

      expect(result.file.parserDiagnostics).toEqual([]);
      expect(result.file.hydrationDiagnostics).toMatchObject([{ kind: 'invalidParameterDoc' }]);
    });

    test('コロンのない型宣言を文書診断にする', () => {
      const comment = '# $code [code] commands';

      const result = hydrate(comment);

      expect(result.file.parserDiagnostics).toEqual([]);
      expect(result.file.hydrationDiagnostics).toMatchObject([{ kind: 'invalidParameterDoc' }]);
    });

    test('example内の型宣言を引数へ混ぜない', () => {
      const result = hydrate('# example:\n#   $code [code]: example only');

      expect(result.documentation?.parameters).toEqual([]);
      expect(result.documentation?.examples[0].text).toContain('[code]');
    });
  });
});

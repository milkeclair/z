import { describe, expect, test } from 'vitest';
import { tokensInRange } from '../../../src/zshParser/parser';
import { commandFromItem, parse, simpleCommandFromItem } from './helper';

describe('parse@comment', () => {
  test('commentはfileに保持しcommandの構造からは除外する', () => {
    const result = parse('# doc\necho foo # inline\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    expect(result.ast.comments.map((comment) => comment.text)).toEqual(['# doc', '# inline']);
    expect(command.commandName?.value).toBe('echo');
    expect(command.arguments.map((argument) => argument.raw)).toEqual(['foo']);
    expect(tokensInRange(result.tokens, command.range).map((token) => token.value)).toEqual([
      'echo',
      ' ',
      'foo',
    ]);
    expect(command.range.end).toEqual(command.arguments[0]?.range.end);
  });

  test('parameter expansion内の#はfileのcommentにしない', () => {
    const result = parse('local line_count=${#lines[@]}\nstr=${str##[[:space:]]##}\n');

    expect(result.ast.comments).toEqual([]);
  });

  test('inline commentは次の関数のDocBlockにしない', () => {
    const result = parse('echo foo # inline\nfoo() { echo hi }\n');
    const command = commandFromItem(result.ast.body.items[1]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      leadingDoc: null,
    });
  });
});

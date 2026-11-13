import { describe, expect, test } from 'vitest';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@precommand', () => {
  test('commandのoptionはmodifierに入りcommandNameから除外する', () => {
    const command = simpleCommandFromItem(parse('command -p typeset foo=bar\n').ast.body.items[0]);

    expect(command.precommandModifiers).toMatchObject([
      {
        type: 'command',
        options: [
          {
            name: '-p',
            value: null,
          },
        ],
      },
    ]);
    expect(command.commandName?.value).toBe('typeset');
    expect(command.arguments.map((argument) => argument.raw)).toEqual(['foo=bar']);
    expect(command.semantic).toEqual({ role: 'normal' });
  });

  test('execの-aは値を持つoptionとして読む', () => {
    const command = simpleCommandFromItem(parse('exec -cl -a shell zsh\n').ast.body.items[0]);

    expect(command.precommandModifiers).toMatchObject([
      {
        type: 'exec',
        options: [
          {
            name: '-cl',
            value: null,
          },
          {
            name: '-a',
            value: {
              raw: 'shell',
            },
          },
        ],
      },
    ]);
    expect(command.commandName?.value).toBe('zsh');
  });

  test('nocorrectは他のprecommand modifierの後ではcommandNameとして読む', () => {
    const command = simpleCommandFromItem(parse('command nocorrect echo ok\n').ast.body.items[0]);

    expect(command.precommandModifiers.map((modifier) => modifier.type)).toEqual(['command']);
    expect(command.commandName?.value).toBe('nocorrect');
    expect(command.arguments.map((argument) => argument.raw)).toEqual(['echo', 'ok']);
  });
});

test('exec -aの置換もWordと本体ASTで保持する', () => {
  const result = parse('exec -a $(print custom) echo ok');
  expect(result.diagnostics).toEqual([]);
  expect(simpleCommandFromItem(result.ast.body.items[0]).precommandModifiers).toMatchObject([{
    type: 'exec', options: [{ name: '-a', value: { raw: '$(print custom)', parts: [{ kind: 'commandSubstitution', body: { items: expect.any(Array) } }] } }],
  }]);
});

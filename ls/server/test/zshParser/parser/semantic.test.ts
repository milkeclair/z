import { describe, expect, test } from 'vitest';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@semantic', () => {
  test('sourceはsourceのsemanticを持つ', () => {
    const command = simpleCommandFromItem(parse('source somefile\n').ast.body.items[0]);

    expect(command.semantic).toMatchObject({
      role: 'source',
      source: {
        form: 'source',
        target: {
          kind: 'word',
          raw: 'somefile',
        },
      },
    });
  });

  test('dotはsourceのsemanticを持つ', () => {
    const command = simpleCommandFromItem(parse('. ./somefile\n').ast.body.items[0]);

    expect(command.semantic).toMatchObject({
      role: 'source',
      source: {
        form: 'dot',
        target: {
          raw: './somefile',
        },
      },
    });
  });

  test('localはdeclarationのsemanticを持つ', () => {
    const command = simpleCommandFromItem(parse('local somevar=$other name\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => argument.raw)).toEqual(['somevar=$other', 'name']);
    expect(command.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        kind: 'local',
        syntaxMode: 'reservedWord',
        assignments: [
          {
            kind: 'assign',
            name: {
              value: 'somevar',
            },
            value: {
              value: {
                raw: '$other',
              },
            },
          },
        ],
        names: [
          {
            value: 'name',
          },
        ],
      },
    });
  });

  test('builtin経由のtypesetはbuiltinInterfaceのdeclarationになる', () => {
    const command = simpleCommandFromItem(parse('builtin typeset foo=bar\n').ast.body.items[0]);

    expect(command.precommandModifiers.map((modifier) => modifier.type)).toEqual(['builtin']);
    expect(command.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        kind: 'typeset',
        syntaxMode: 'builtinInterface',
      },
    });
  });

  test('command経由のtypesetはdeclarationにしない', () => {
    const command = simpleCommandFromItem(parse('command typeset foo=bar\n').ast.body.items[0]);

    expect(command.precommandModifiers.map((modifier) => modifier.type)).toEqual(['command']);
    expect(command.semantic).toEqual({ role: 'normal' });
  });
});

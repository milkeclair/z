import { describe, expect, test } from 'vitest';
import { findAll } from '../../../src/zshParser/ast';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@processSubstitution', () => {

  test.each([' ', '\t', '\n'])('配列内のfile置換を保持する: %j', (gap) => {
    const source = 'items=(' + gap + '=(cat <<EOF\n) literal\nEOF\n))\n';
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
    expect(findAll(result.ast, 'hereDocument')[0]?.raw).toBe(') literal\n');
  });
  test.each([
    'for item in <(print x); do :; done',
    'select item in <(print x); do :; done',
    'foreach item (<(print x))\n:\nend',
    'case <(print x) in *) :;; esac',
    'repeat <(print x) do :; done',
  ])('wordを要求する位置で置換を一つのwordとして読む: %s', (source) => {
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
    expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
  });

  test('配列中の置換にも独立したcommandの字句状態を持つ', () => {
    const source = 'items=(<(cat <<EOF\n) literal # $fake\nEOF\n))\n# after\n';
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    expect(result.ast.comments.map((node) => node.text)).toEqual(['# after']);
    expect(findAll(result.ast, 'hereDocument')[0].raw).toBe(') literal # $fake\n');
  });

  test.each([
    { raw: '<(print x)', direction: 'input' },
    { raw: '>(print x)', direction: 'output' },
    { raw: '=(print x)', direction: 'file' },
  ])('$directionの本体をASTとして保持する', ({ raw, direction }) => {
    const result = parse('cat ' + raw);
    expect(result.diagnostics).toEqual([]);
    const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];
    expect(argument).toMatchObject({ raw, parts: [{ kind: 'processSubstitution', raw, direction,
      body: { items: [{ sublist: { first: { first: { kind: 'simpleCommand', commandName: { value: 'print' } } } } }] } }] });
  });
});

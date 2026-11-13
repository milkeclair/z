import { describe, expect, test } from 'vitest';
import { parse, sublistFromItem } from './helper';

describe('parse@operator', () => {
  test('pipelineはoperatorと後続commandをrestに持つ', () => {
    const sublist = sublistFromItem(parse('foo |& bar | baz\n').ast.body.items[0]);

    expect(sublist.first.first.kind).toBe('simpleCommand');
    expect(sublist.first.rest.map((continuation) => continuation.operator.type)).toEqual([
      'pipeErr',
      'pipe',
    ]);
    expect(
      sublist.first.rest.map((continuation) =>
        continuation.command.kind === 'simpleCommand'
          ? continuation.command.commandName?.value
          : continuation.command.kind,
      ),
    ).toEqual(['bar', 'baz']);
  });

  test('sublistはlogicalOperatorと後続pipelineをrestに持つ', () => {
    const sublist = sublistFromItem(parse('foo && bar || baz\n').ast.body.items[0]);

    expect(sublist.rest.map((continuation) => continuation.operator.type)).toEqual([
      'andIf',
      'orIf',
    ]);
    expect(
      sublist.rest.map((continuation) =>
        continuation.pipeline.first.kind === 'simpleCommand'
          ? continuation.pipeline.first.commandName?.value
          : continuation.pipeline.first.kind,
      ),
    ).toEqual(['bar', 'baz']);
  });

  test('logicalOperator直後の改行は後続pipelineの前で継続として読む', () => {
    const result = parse('foo &&\n  bar ||\n  baz\n');
    const sublist = sublistFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(sublist.rest.map((continuation) => continuation.operator.type)).toEqual([
      'andIf',
      'orIf',
    ]);
    expect(
      sublist.rest.map((continuation) =>
        continuation.pipeline.first.kind === 'simpleCommand'
          ? continuation.pipeline.first.commandName?.value
          : continuation.pipeline.first.kind,
      ),
    ).toEqual(['bar', 'baz']);
  });

  test('pipelineOperator直後の改行は後続commandの前で継続として読む', () => {
    const result = parse('foo |\n  bar |&\n  baz\n');
    const sublist = sublistFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(sublist.first.rest.map((continuation) => continuation.operator.type)).toEqual([
      'pipe',
      'pipeErr',
    ]);
    expect(
      sublist.first.rest.map((continuation) =>
        continuation.command.kind === 'simpleCommand'
          ? continuation.command.commandName?.value
          : continuation.command.kind,
      ),
    ).toEqual(['bar', 'baz']);
  });

  test('pipelineModifierは1つだけ保持する', () => {
    const result = parse('! coproc foo\n');
    const sublist = sublistFromItem(result.ast.body.items[0]);

    expect(sublist.first.modifier?.type).toBe('bang');
    expect(result.diagnostics).toMatchObject([
      {
        kind: 'unexpectedToken',
      },
    ]);
    expect(sublist.first.first.kind === 'simpleCommand' ? sublist.first.first.commandName?.value : null).toBe(
      'foo',
    );
  });

  test('timeはpipeline全体のtimingとして保持する', () => {
    const result = parse('time ! echo ok | cat\n');
    const sublist = sublistFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(sublist.first.timing).toMatchObject({
      kind: 'pipelineTiming',
    });
    expect(sublist.first.modifier?.type).toBe('bang');
    expect(sublist.first.first.kind === 'simpleCommand' ? sublist.first.first.commandName?.value : null).toBe(
      'echo',
    );
    expect(
      sublist.first.rest.map((continuation) =>
        continuation.command.kind === 'simpleCommand'
          ? continuation.command.commandName?.value
          : continuation.command.kind,
      ),
    ).toEqual(['cat']);
  });
});

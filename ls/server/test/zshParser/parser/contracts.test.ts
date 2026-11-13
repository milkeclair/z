import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { mapAst } from '../../../src/zshParser/ast';
import { astContractViolations } from './contracts';

describe('ast@contracts', () => {
  test('既知のraw破損とword parts欠落を検出する', () => {
    const source = 'echo value';
    const parsed = Parser.parse(Lexer.tokenize(source).tokens);
    const rawBroken = mapAst(parsed.ast, (node) => node.kind === 'word' ? { ...node, raw: node.raw + 'broken' } : node);
    expect(astContractViolations(rawBroken, parsed.tokens, source)).toContain('rawRange:word');
    const partsBroken = mapAst(parsed.ast, (node) => node.kind === 'word' ? { ...node, parts: [] } : node);
    expect(astContractViolations(partsBroken, parsed.tokens, source)).toContain('wordParts');
  });
  test('既知の座標・token欠落を検出する', () => {
    const source = 'echo value\r\n';
    const parsed = Parser.parse(Lexer.tokenize(source).tokens);
    const broken = { ...parsed.ast, range: { ...parsed.ast.range, end: { offset: source.length + 1, line: 1, character: 0 } } };
    expect(astContractViolations(broken, parsed.tokens, source)).toContain('nodeRange:file');
    expect(astContractViolations(parsed.ast, parsed.tokens.slice(1), source)).toContain('tokenCoverage');
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
  });
  test('既知のunsupported構文のunknownも検出する', () => {
    const source = '}';
    const parsed = Parser.parse(Lexer.tokenize(source).tokens);
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toContain('unknown');
  });
});

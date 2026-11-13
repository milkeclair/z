import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { astContractViolations } from './contracts';
import { locate, createQueryContext, findAll } from '../../../src/zshParser/ast';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@hereDocument', () => {

  test.each([' # note', '#EOF', '\\\n # note'])('終端語の欠落とコメントを区別する: %s', (header) => {
    const parsed = parse('cat <<' + header + '\nprint after\n');
    expect(parsed.diagnostics.some((item) => item.kind === 'unexpectedToken')).toBe(true);
    expect(parsed.ast.comments).toHaveLength(1);
    expect(findAll(parsed.ast, 'hereDocument')).toEqual([]);
    expect(parsed.ast.body.items).toHaveLength(2);
  });

  test('終端語の継続行は本文を引用扱いにしない', () => {
    const source = 'cat <<EO\\\nF\n$value\nEOF\n';
    const parsed = parse(source);
    expect(Lexer.tokenize(source).diagnostics).toEqual([]);
    expect(findAll(parsed.ast, 'hereDocument')[0]).toMatchObject({ delimiter: 'EOF', quoted: false });
  });

  test('<<-は継続で連結した行の途中のタブを保持して終端を照合する', () => {
    const source = 'cat <<-EOF\nEO\\\n\tF\nEOF\nprint after\n';
    const parsed = parse(source);
    expect(Lexer.tokenize(source).diagnostics).toEqual([]);
    expect(findAll(parsed.ast, 'hereDocument')[0]?.raw).toBe('EO\\\n\tF\n');
    expect(parsed.ast.body.items).toHaveLength(2);
  });

  test('深い未完成の終端語でもヒアドキュメント検出を再帰させない', () => {
    const delimiter = '$(cat <<'.repeat(2000) + 'EOF' + ')'.repeat(2000);
    const source = 'cat <<' + delimiter + '\n';
    const lexed = Lexer.tokenize(source);
    expect(lexed.tokens.map((token) => token.value).join('')).toBe(source);
    expect(lexed.diagnostics.map((item) => item.kind)).toEqual(['unclosedHereDocument']);
  });

  test.each([
    ['EOF', 'EO\\\nF\n', ''],
    ['EOF', 'x\\\nEOF\n) # literal\nEOF\n', 'x\\\nEOF\n) # literal\n'],
    ["'EOF'", 'x\\\nEOF\n', 'x\\\n'],
    ['EOF', '\\\\\nEOF\n', '\\\\\n'],
  ])('終端照合は引用状態と継続行に従う: %s / %s', (header, input, raw) => {
    for (const nested of [false, true]) {
      const command = 'cat <<' + header + '\n' + input;
      const source = (nested ? 'print "$(' + command + ')"\n' : command) + 'print after\n';
      const lexed = Lexer.tokenize(source);
      const parsed = parse(source);
      expect(lexed.diagnostics).toEqual([]);
      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(parsed.ast.body.items).toHaveLength(2);
      const commandNode = simpleCommandFromItem(parsed.ast.body.items[0]);
      if (nested) {
        expect(commandNode.arguments[0].parts.find((part) => part.kind === 'commandSubstitution')).toMatchObject({
          kind: 'commandSubstitution', body: { items: [{ sublist: {
            first: { first: { redirects: [{ hereDocument: { raw } }] } },
          } }] },
        });
      } else expect(commandNode.redirects[0].hereDocument?.raw).toBe(raw);
    }
  });

  test.each([
    ['$' + '{x}', '$' + '{x}'],
    ['$' + '{x:-"E"}', '$' + '{x:-E}'],
    ['$(print x)', '$(print x)'],
    ['$(print "x")', '$(print "x")'],
    [String.fromCharCode(96) + 'EOF' + String.fromCharCode(96), String.fromCharCode(96) + 'EOF' + String.fromCharCode(96)],
    ["$'\\xc3\\xa9'", 'é'],
    ["$'\\xef\\xbb\\xbfEOF'", '\ufeffEOF'],
    ["$'EOF'", 'EOF'],
    ["$'E\\x4fF'", 'EOF'],
    ["$'E\\117F'", 'EOF'],
    ["$'E\\u004fF'", 'EOF'],
    ["$'E\\U0000004fF'", 'EOF'],
    ["$'E\\qF'", 'EqF'],
    ["$'E\\tF'", 'E\tF'],
    ['"E\\OF"', 'E\\OF'],
    ['E\\OF', 'EOF'],
    ['E"OF"', 'EOF'],
    ["'\tEOF'", '\tEOF'],
  ])('終端のquote removalを適用できる文脈で保つ: %s', (header, delimiter) => {
    for (const nested of header.startsWith('$(') ? [false] : [false, true]) {
      const command = 'cat <<' + header + '\n) # literal\n' + delimiter + '\n';
      const source = (nested ? 'print "$(' + command + ')"\n' : command) + 'print after\n';
      const lexed = Lexer.tokenize(source);
      const parsed = parse(source);
      expect(lexed.diagnostics).toEqual([]);
      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(parsed.ast.body.items).toHaveLength(2);
      const targets = findAll(parsed.ast, 'redirect').map((node) => node.target);
      expect(targets).toHaveLength(1);
      expect(targets[0]?.parts).toEqual([{ kind: 'stringLiteral', range: targets[0]?.range, value: header }]);
    }
  });

  test('<<-は終端語自体の先頭タブも除く', () => {
    const source = "cat <<-'\tEOF'\n\tbody\n\tEOF\nprint after\n";
    const lexed = Lexer.tokenize(source);
    const parsed = parse(source);
    expect(lexed.diagnostics).toEqual([]);
    expect(parsed.ast.body.items).toHaveLength(2);
    expect(simpleCommandFromItem(parsed.ast.body.items[0]).redirects[0].hereDocument).toMatchObject({
      delimiter: 'EOF', raw: '\tbody\n',
    });
  });
  test.each(['{ : } always { : }', 'helper() cat'])(
    '末尾の本文を持つ子のrangeまで親にも保持する: %s', (header) => {
      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);
      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body'))).toMatchObject({
        kind: 'syntax', node: { kind: 'hereDocument', raw: 'body\n' },
      });
    },
  );

  test('置換の内外で別々のheredocキューを保持する', () => {
    const source = 'cat <<OUT $(cat <<IN\ninner\nIN\n)\nouter\nOUT\n';
    const parsed = parse(source);
    expect(parsed.diagnostics).toEqual([]);
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    const outer = simpleCommandFromItem(parsed.ast.body.items[0]);
    expect(outer.redirects[0].hereDocument?.raw).toBe('outer\n');
    expect(outer.arguments[0].parts).toMatchObject([{ kind: 'commandSubstitution',
      body: { items: [{ sublist: { first: { first: { redirects: [{ hereDocument: { raw: 'inner\n' } }] } } } }] } }]);
  });

  test('外側のheredocは置換内の改行で始めない', () => {
    const source = 'cat <<EOF $(printf x\n)\nbody\nEOF\n';
    const parsed = parse(source);
    expect(parsed.diagnostics).toEqual([]);
    expect(simpleCommandFromItem(parsed.ast.body.items[0]).arguments[0].raw).toBe('$(printf x\n)');
    expect(simpleCommandFromItem(parsed.ast.body.items[0]).redirects[0].hereDocument?.raw).toBe('body\n');
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
  });

  test('条件の置換内のheredocが外側の字句状態を変えない', () => {
    const source = '[[ $(cat <<EOF\n(( literal\nEOF\n) == x ]]\necho ok # trailing\n';
    const parsed = parse(source);
    expect(parsed.diagnostics).toEqual([]);
    expect(parsed.ast.comments.map((node) => node.text)).toEqual(['# trailing']);
    expect(simpleCommandFromItem(parsed.ast.body.items[1]).arguments.map((word) => word.raw)).toEqual(['ok']);
  });

  test.each([
    'helper() { : }', '{ : }', '( : )', 'if true; then :; fi', '[[ -n x ]]', 'repeat 2 print x',
  ])('複合構文の後の本文まで所有rangeと位置検索が届く: %s', (header) => {
    const source = header + ' <<EOF\nbody\nEOF\n';
    const parsed = parse(source);
    expect(parsed.diagnostics).toEqual([]);
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
      kind: 'syntax', node: { kind: 'hereDocument', raw: 'body\n' },
    });
  });

  test('置換内のhere-documentの括弧を置換の終端にしない', () => {
    const result = parse('echo "$(cat <<EOF\n) literal\nEOF\n)"');
    expect(result.diagnostics).toEqual([]);
    const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];
    expect(argument.raw).toBe('"$(cat <<EOF\n) literal\nEOF\n)"');
    expect(argument.parts.find((part) => part.kind === 'commandSubstitution')).toMatchObject({
      body: { items: [{ sublist: { first: { first: { redirects: [{ hereDocument: { raw: ') literal\n' } }] } } } }] },
    });
  });

  test('算術式のshiftをhere-documentとして扱わない', () => {
    const source = 'for ((i=1<<2; i<8; i++)); do\nprint "$i"\ndone\n';
    expect(Lexer.tokenize(source).diagnostics).toEqual([]);
    expect(parse(source).diagnostics).toEqual([]);
  });

  test('本文のcommandやcommentを実行構文として解析しない', () => {
    const source = "cat <<'EOF'\nif ) # literal $value\nEOF\necho after\n";
    const lexed = Lexer.tokenize(source);
    const result = parse(source);
    expect(lexed.diagnostics).toEqual([]);
    expect(lexed.tokens.map((token) => token.value).join('')).toBe(source);
    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(2);
    expect(result.ast.comments).toEqual([]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).redirects[0]).toMatchObject({
      operator: '<<', hereDocument: { kind: 'hereDocument', delimiter: 'EOF', quoted: true,
        stripTabs: false, raw: 'if ) # literal $value\n', close: { start: { line: 2 } } },
    });
  });
  test('同じ行の複数here-documentを出現順に対応させる', () => {
    const result = parse('cat <<A <<-B\none\nA\n\ttwo\n\tB\n');
    const redirects = simpleCommandFromItem(result.ast.body.items[0]).redirects;
    expect(result.diagnostics).toEqual([]);
    expect(redirects.map((node) => node.hereDocument?.raw)).toEqual(['one\n', '\ttwo\n']);
    expect(redirects[1].hereDocument?.stripTabs).toBe(true);
  });
  test('未終端でも本文とlexer診断を保持する', () => {
    const lexed = Lexer.tokenize('cat <<EOF\nbody\n');
    expect(lexed.diagnostics.map((item) => item.kind)).toEqual(['unclosedHereDocument']);
    const result = parse('cat <<EOF\nbody\n');
    expect(simpleCommandFromItem(result.ast.body.items[0]).redirects[0].hereDocument).toMatchObject({ raw: 'body\n', close: null });
  });
});

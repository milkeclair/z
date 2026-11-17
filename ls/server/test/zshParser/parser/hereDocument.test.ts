import { describe, expect, test } from 'vitest';
import { createQueryContext, findAll, locate } from '../../../src/zshParser/ast';
import { Lexer } from '../../../src/zshParser/lexer';
import { astContractViolations } from './contracts';
import { parse, simpleCommandFromItem } from './helper';

describe('Parser.parse', () => {
  describe('ヒアドキュメントを解析する場合', () => {
    test('終端語の前に空白とコメントだけがある場合を診断する', () => {
      const header = ' # note';

      const parsed = parse('cat <<' + header + '\nprint after\n');

      expect(parsed.diagnostics.some((item) => item.kind === 'unexpectedToken')).toBe(true);
      expect(parsed.ast.comments).toHaveLength(1);
      expect(findAll(parsed.ast, 'hereDocument')).toEqual([]);
      expect(parsed.ast.body.items).toHaveLength(2);
    });

    test('空白のないハッシュを終端語として保持する', () => {
      const header = '#EOF';

      const parsed = parse('cat <<' + header + '\nprint after\n');

      expect(parsed.diagnostics.some((item) => item.kind === 'unexpectedToken')).toBe(true);
      expect(parsed.ast.comments).toHaveLength(1);
      expect(findAll(parsed.ast, 'hereDocument')).toEqual([]);
      expect(parsed.ast.body.items).toHaveLength(2);
    });

    test('行継続の後にコメントだけがある場合を診断する', () => {
      const header = '\\\n # note';

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
      expect(findAll(parsed.ast, 'hereDocument')[0]).toMatchObject({
        delimiter: 'EOF',
        quoted: false,
      });
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

    test('継続で連結された終端語を認識する', () => {
      const header = 'EOF';
      const input = 'EO\\\nF\n';
      const raw = '';

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
          expect(
            commandNode.arguments[0].parts.find((part) => part.kind === 'commandSubstitution'),
          ).toMatchObject({
            kind: 'commandSubstitution',
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { redirects: [{ hereDocument: { raw } }] } },
                  },
                },
              ],
            },
          });
        } else {
          expect(commandNode.redirects[0].hereDocument?.raw).toBe(raw);
        }
      }
    });

    test('本文と継続で連結された終端語を閉じとして扱わない', () => {
      const header = 'EOF';
      const input = 'x\\\nEOF\n) # literal\nEOF\n';
      const raw = 'x\\\nEOF\n) # literal\n';

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
          expect(
            commandNode.arguments[0].parts.find((part) => part.kind === 'commandSubstitution'),
          ).toMatchObject({
            kind: 'commandSubstitution',
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { redirects: [{ hereDocument: { raw } }] } },
                  },
                },
              ],
            },
          });
        } else {
          expect(commandNode.redirects[0].hereDocument?.raw).toBe(raw);
        }
      }
    });

    test('引用した終端語の本文では行継続を解除しない', () => {
      const header = "'EOF'";
      const input = 'x\\\nEOF\n';
      const raw = 'x\\\n';

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
          expect(
            commandNode.arguments[0].parts.find((part) => part.kind === 'commandSubstitution'),
          ).toMatchObject({
            kind: 'commandSubstitution',
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { redirects: [{ hereDocument: { raw } }] } },
                  },
                },
              ],
            },
          });
        } else {
          expect(commandNode.redirects[0].hereDocument?.raw).toBe(raw);
        }
      }
    });

    test('エスケープされたバックスラッシュを本文へ残す', () => {
      const header = 'EOF';
      const input = '\\\\\nEOF\n';
      const raw = '\\\\\n';

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
          expect(
            commandNode.arguments[0].parts.find((part) => part.kind === 'commandSubstitution'),
          ).toMatchObject({
            kind: 'commandSubstitution',
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { redirects: [{ hereDocument: { raw } }] } },
                  },
                },
              ],
            },
          });
        } else {
          expect(commandNode.redirects[0].hereDocument?.raw).toBe(raw);
        }
      }
    });

    test('終端語の変数名を展開せず保持する', () => {
      const header = '$' + '{x}';
      const delimiter = '$' + '{x}';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('終端語の変数展開構文では引用だけを解除する', () => {
      const header = '$' + '{x:-"E"}';
      const delimiter = '$' + '{x:-E}';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('終端語のコマンド置換表記を実行せず保持する', () => {
      const header = '$(print x)';
      const delimiter = '$(print x)';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('コマンド置換表記の内側の引用符を保持する', () => {
      const header = '$(print "x")';
      const delimiter = '$(print "x")';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('終端語のバッククォートを実行せず保持する', () => {
      const header = String.fromCharCode(96) + 'EOF' + String.fromCharCode(96);
      const delimiter = String.fromCharCode(96) + 'EOF' + String.fromCharCode(96);

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用のUTF-8バイトを復号する', () => {
      const header = "$'\\xc3\\xa9'";
      const delimiter = 'é';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用のBOMを保持する', () => {
      const header = "$'\\xef\\xbb\\xbfEOF'";
      const delimiter = '\ufeffEOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の通常文字列を読む', () => {
      const header = "$'EOF'";
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の16進エスケープを復号する', () => {
      const header = "$'E\\x4fF'";
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の8進エスケープを復号する', () => {
      const header = "$'E\\117F'";
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の4桁Unicodeを復号する', () => {
      const header = "$'E\\u004fF'";
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の8桁Unicodeを復号する', () => {
      const header = "$'E\\U0000004fF'";
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用の未知のエスケープを文字として扱う', () => {
      const header = "$'E\\qF'";
      const delimiter = 'EqF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('ANSI引用のタブを復号する', () => {
      const header = "$'E\\tF'";
      const delimiter = 'E\tF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('二重引用内の通常文字へのバックスラッシュを保持する', () => {
      const header = '"E\\OF"';
      const delimiter = 'E\\OF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('引用外のバックスラッシュを解除する', () => {
      const header = 'E\\OF';
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('途中にある二重引用を解除する', () => {
      const header = 'E"OF"';
      const delimiter = 'EOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('単引用内のタブを保持する', () => {
      const header = "'\tEOF'";
      const delimiter = '\tEOF';

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
        expect(targets[0]?.parts).toEqual([
          { kind: 'stringLiteral', range: targets[0]?.range, value: header },
        ]);
      }
    });

    test('<<-は終端語自体の先頭タブも除く', () => {
      const source = "cat <<-'\tEOF'\n\tbody\n\tEOF\nprint after\n";
      const lexed = Lexer.tokenize(source);
      const parsed = parse(source);

      expect(lexed.diagnostics).toEqual([]);
      expect(parsed.ast.body.items).toHaveLength(2);
      expect(
        simpleCommandFromItem(parsed.ast.body.items[0]).redirects[0].hereDocument,
      ).toMatchObject({
        delimiter: 'EOF',
        raw: '\tbody\n',
      });
    });

    test('always節の後の本文まで親の範囲に含める', () => {
      const header = '{ : } always { : }';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body'))).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('関数本体コマンドの後の本文まで親の範囲に含める', () => {
      const header = 'helper() cat';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body'))).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('置換の内外で別々のheredocキューを保持する', () => {
      const source = 'cat <<OUT $(cat <<IN\ninner\nIN\n)\nouter\nOUT\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      const outer = simpleCommandFromItem(parsed.ast.body.items[0]);

      expect(outer.redirects[0].hereDocument?.raw).toBe('outer\n');
      expect(outer.arguments[0].parts).toMatchObject([
        {
          kind: 'commandSubstitution',
          body: {
            items: [
              {
                sublist: {
                  first: { first: { redirects: [{ hereDocument: { raw: 'inner\n' } }] } },
                },
              },
            ],
          },
        },
      ]);
    });

    test('外側のheredocは置換内の改行で始めない', () => {
      const source = 'cat <<EOF $(printf x\n)\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(simpleCommandFromItem(parsed.ast.body.items[0]).arguments[0].raw).toBe(
        '$(printf x\n)',
      );
      expect(simpleCommandFromItem(parsed.ast.body.items[0]).redirects[0].hereDocument?.raw).toBe(
        'body\n',
      );
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    });

    test('条件の置換内のheredocが外側の字句状態を変えない', () => {
      const source = '[[ $(cat <<EOF\n(( literal\nEOF\n) == x ]]\necho ok # trailing\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(parsed.ast.comments.map((node) => node.text)).toEqual(['# trailing']);
      expect(
        simpleCommandFromItem(parsed.ast.body.items[1]).arguments.map((word) => word.raw),
      ).toEqual(['ok']);
    });

    test('関数定義の後の本文まで範囲と位置検索を保つ', () => {
      const header = 'helper() { : }';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('グループの後の本文まで範囲と位置検索を保つ', () => {
      const header = '{ : }';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('サブシェルの後の本文まで範囲と位置検索を保つ', () => {
      const header = '( : )';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('ifの後の本文まで範囲と位置検索を保つ', () => {
      const header = 'if true; then :; fi';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('条件式の後の本文まで範囲と位置検索を保つ', () => {
      const header = '[[ -n x ]]';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('repeatの後の本文まで範囲と位置検索を保つ', () => {
      const header = 'repeat 2 print x';

      const source = header + ' <<EOF\nbody\nEOF\n';
      const parsed = parse(source);

      expect(parsed.diagnostics).toEqual([]);
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
      expect(locate(createQueryContext(parsed.ast), source.indexOf('body') + 1)).toMatchObject({
        kind: 'syntax',
        node: { kind: 'hereDocument', raw: 'body\n' },
      });
    });

    test('置換内のhere-documentの括弧を置換の終端にしない', () => {
      const result = parse('echo "$(cat <<EOF\n) literal\nEOF\n)"');

      expect(result.diagnostics).toEqual([]);
      const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];

      expect(argument.raw).toBe('"$(cat <<EOF\n) literal\nEOF\n)"');
      expect(argument.parts.find((part) => part.kind === 'commandSubstitution')).toMatchObject({
        body: {
          items: [
            {
              sublist: {
                first: { first: { redirects: [{ hereDocument: { raw: ') literal\n' } }] } },
              },
            },
          ],
        },
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
        operator: '<<',
        hereDocument: {
          kind: 'hereDocument',
          delimiter: 'EOF',
          quoted: true,
          stripTabs: false,
          raw: 'if ) # literal $value\n',
          close: { start: { line: 2 } },
        },
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

      expect(
        simpleCommandFromItem(result.ast.body.items[0]).redirects[0].hereDocument,
      ).toMatchObject({ raw: 'body\n', close: null });
    });
  });
});

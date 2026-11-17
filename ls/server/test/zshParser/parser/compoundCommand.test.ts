import { describe, expect, test } from 'vitest';
import { findAll } from '../../../src/zshParser/ast';
import { commandFromItem, parse } from './helper';

describe('Parser.parse', () => {
  describe('複合コマンドを解析する場合', () => {
    test('二段の算術括弧をforヘッダの終端と区別する', () => {
      const expression = '((1)+2)';

      const source = 'for ((i=' + expression + '; i<4; i++)); do :; done';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for required');
      }

      expect(command.arithmetic?.raw).toBe('((i=' + expression + '; i<4; i++))');
    });

    test('三段の算術括弧をforヘッダの終端と区別する', () => {
      const expression = '(((1)+2))';

      const source = 'for ((i=' + expression + '; i<4; i++)); do :; done';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for required');
      }

      expect(command.arithmetic?.raw).toBe('((i=' + expression + '; i<4; i++))');
    });

    test('repeatの回数不足を診断する', () => {
      const source = 'repeat ; do :; done';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('caseの比較対象不足を診断する', () => {
      const source = 'case ; in *) :;; esac';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('caseのパターン不足を診断する', () => {
      const source = 'case x in ) :;; esac';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('算術forの区切りがない場合を診断する', () => {
      const source = 'for ((i=1)); do :; done';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('算術forの区切りが一つだけの場合を診断する', () => {
      const source = 'for ((i=1; i<3)); do :; done';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('算術forの区切りは置換内や括弧内のセミコロンと区別する', () => {
      const source = 'for ((i=$(print 0; print 1); i<3; i++)); do :; done';

      expect(parse(source).diagnostics).toEqual([]);
    });

    test('算術forは通常の括弧を含むヘッダ全体を保持する', () => {
      const source = 'for ((i=(1+(2)); i<4; i++)); do print "$i"; done';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for required');
      }

      expect(command.arithmetic?.raw).toBe('((i=(1+(2)); i<4; i++))');
      expect(findAll(command.body, 'simpleCommand')[0].commandName?.value).toBe('print');
    });

    test('forの変数不足を診断する', () => {
      const source = 'for ; do :; done';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('selectの変数不足を診断する', () => {
      const source = 'select ; do :; done';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('foreachの変数不足を診断する', () => {
      const source = 'foreach (one two)\n:\nend';

      expect(parse(source).diagnostics.some((node) => node.kind === 'unexpectedToken')).toBe(true);
    });

    test('doという名前のループ変数を保持する', () => {
      const source = 'for do in one; do print "$do"; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for command required');
      }

      expect(command.variables).toHaveLength(1);
      expect(command.words?.length).toBeGreaterThan(0);
    });

    test('inという名前のループ変数を保持する', () => {
      const source = 'for in in one; do print "$in"; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for command required');
      }

      expect(command.variables).toHaveLength(1);
      expect(command.words?.length).toBeGreaterThan(0);
    });

    test('括弧で囲んだ列挙値を保持する', () => {
      const source = 'for item (one two); do print "$item"; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'forCommand') {
        throw new Error('for command required');
      }

      expect(command.variables).toHaveLength(1);
      expect(command.words?.length).toBeGreaterThan(0);
    });

    test('repeatのdo形式が未終端なら構文診断を返す', () => {
      expect(parse('repeat 3 do print x').diagnostics.map((item) => item.kind)).toEqual([
        'missingCompoundEnd',
      ]);
    });

    test('ifの各条件、本体、else、redirectを辿れる', () => {
      const result = parse(
        'if ready; then first() { : }; elif other; then second() { : }; else third() { : }; fi >out',
      );

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'ifCommand') {
        throw new Error('if command required');
      }

      expect(command.branches).toHaveLength(2);
      expect(command.branches[0].condition.items).toHaveLength(1);
      expect(command.branches[1].body.items).toHaveLength(1);
      expect(command.elseBody?.items).toHaveLength(1);
      expect(command.postBodyRedirects[0].target?.raw).toBe('out');
      expect(findAll(result.ast, 'functionDefinition').map((node) => node.names[0].raw)).toEqual([
        'first',
        'second',
        'third',
      ]);
    });

    test('通常forの本体を構造として保持する', () => {
      const source = 'for item in one "two three"; do print "$item"; done';
      const kind = 'forCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('算術forの本体を構造として保持する', () => {
      const source = 'for ((i=0; i<3; i++)); do print "$i"; done';
      const kind = 'forCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('selectの本体を構造として保持する', () => {
      const source = 'select item in one two; do print "$item"; done';
      const kind = 'selectCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('foreachの本体を構造として保持する', () => {
      const source = 'foreach item (one two)\nprint "$item"\nend';
      const kind = 'foreachCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('do形式のrepeat本体を構造として保持する', () => {
      const source = 'repeat 3 do print ok; done';
      const kind = 'repeatCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('単一コマンドのrepeat本体を構造として保持する', () => {
      const source = 'repeat 3 print ok';
      const kind = 'repeatCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('グループ形式のrepeat本体を構造として保持する', () => {
      const source = 'repeat 3 { print ok }';
      const kind = 'repeatCommand';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind,
        body: { kind: 'list', items: expect.any(Array) },
      });
      expect(
        findAll(result.ast, 'simpleCommand').some((node) => node.commandName?.value === 'print'),
      ).toBe(true);
    });

    test('caseの複数patternと各終端を区別する', () => {
      const result = parse('case "$x" in a|b) print one ;& c) print two ;| *) print end ;; esac');

      expect(result.diagnostics).toEqual([]);
      const command = commandFromItem(result.ast.body.items[0]);

      if (command.kind !== 'caseCommand') {
        throw new Error('case command required');
      }

      expect(command.subject?.raw).toBe('"$x"');
      expect(command.arms.map((arm) => arm.patterns.map((word) => word.raw))).toEqual([
        ['a', 'b'],
        ['c'],
        ['*'],
      ]);
      expect(command.arms.map((arm) => arm.termination)).toEqual([';&', ';|', ';;']);
    });

    test('ifは終端まで複合構文ASTとして読む', () => {
      const result = parse('if [[ $x = y ]]; then echo ok; fi\n');
      const command = commandFromItem(result.ast.body.items[0]);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(command).toMatchObject({
        kind: 'ifCommand',
        raw: 'if [[ $x = y ]]; then echo ok; fi',
        close: {
          start: {
            offset: 31,
          },
        },
      });
    });

    test('while後のredirectは同じ複合構文ASTに保持する', () => {
      const result = parse('while read line; do echo $line; done <<< "$names"\n');
      const command = commandFromItem(result.ast.body.items[0]);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(command).toMatchObject({
        kind: 'whileCommand',
        raw: 'while read line; do echo $line; done <<< "$names"',
        postBodyRedirects: [
          {
            operator: '<<<',
            target: {
              raw: '"$names"',
            },
          },
        ],
      });
      expect(result.ast.body.items[0]?.terminator?.type).toBe('newline');
    });

    test('改行後のredirectは複合構文ASTに入れない', () => {
      const result = parse('while read line; do echo $line; done\n<<< "$names"\n');
      const command = commandFromItem(result.ast.body.items[0]);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(command).toMatchObject({
        kind: 'whileCommand',
        postBodyRedirects: [],
      });
    });

    test('reserved wordはcommand先頭のときだけ複合コマンドの終端にする', () => {
      const result = parse(
        'if true; then echo fi; fi\nwhile true; do echo done; done\ncase x in x) echo esac;; esac\n',
      );

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(3);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: 'ifCommand',
        raw: 'if true; then echo fi; fi',
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'whileCommand',
        raw: 'while true; do echo done; done',
      });
      expect(commandFromItem(result.ast.body.items[2])).toMatchObject({
        kind: 'caseCommand',
        raw: 'case x in x) echo esac;; esac',
      });
    });

    test('算術forのヘッダ内でcomment化した文字列があってもdoneまで読む', () => {
      const result = parse('for (( i=1; i<=${#str}; i++ )); do\n  echo $i\ndone\n');
      const command = commandFromItem(result.ast.body.items[0]);

      expect(result.diagnostics).toEqual([]);
      expect(command).toMatchObject({
        kind: 'forCommand',
        close: {
          start: {
            offset: 45,
          },
        },
      });
    });

    test('未終端のreserved commandは次の行の関数定義を吸い込まない', () => {
      const result = parse('if true; then echo ok\nfoo() { echo hi }\n');

      expect(result.diagnostics.map((diagnostic) => diagnostic.kind)).toEqual([
        'missingCompoundEnd',
      ]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: 'ifCommand',
        close: null,
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'functionDefinition',
        names: [
          {
            raw: 'foo',
          },
        ],
      });
    });

    test('条件内のifを越えて外側のfiまで読む', () => {
      const syntax = 'if';
      const source = 'if if true; then true; fi; then true; fi';
      const end = 'fi';

      const result = parse(`${source} >output\necho after\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: syntax + 'Command',
        raw: `${source} >output`,
        close: { start: { offset: source.length - end.length } },
        postBodyRedirects: [{ operator: '>', target: { raw: 'output' } }],
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'simpleCommand',
        commandName: { value: 'echo' },
        arguments: [{ raw: 'after' }],
      });
    });

    test('条件内のifを越えて外側のfiまで読む', () => {
      const syntax = 'if';
      const source = 'if if if true; then true; fi; then true; fi; then true; fi';
      const end = 'fi';

      const result = parse(`${source} >output\necho after\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: syntax + 'Command',
        raw: `${source} >output`,
        close: { start: { offset: source.length - end.length } },
        postBodyRedirects: [{ operator: '>', target: { raw: 'output' } }],
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'simpleCommand',
        commandName: { value: 'echo' },
        arguments: [{ raw: 'after' }],
      });
    });

    test('条件内のwhileを越えて外側のdoneまで読む', () => {
      const syntax = 'while';
      const source = 'while while false; do true; done; do true; done';
      const end = 'done';

      const result = parse(`${source} >output\necho after\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: syntax + 'Command',
        raw: `${source} >output`,
        close: { start: { offset: source.length - end.length } },
        postBodyRedirects: [{ operator: '>', target: { raw: 'output' } }],
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'simpleCommand',
        commandName: { value: 'echo' },
        arguments: [{ raw: 'after' }],
      });
    });

    test('条件内のuntilを越えて外側のdoneまで読む', () => {
      const syntax = 'until';
      const source = 'until until true; do false; done; do true; done';
      const end = 'done';

      const result = parse(`${source} >output\necho after\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(2);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: syntax + 'Command',
        raw: `${source} >output`,
        close: { start: { offset: source.length - end.length } },
        postBodyRedirects: [{ operator: '>', target: { raw: 'output' } }],
      });
      expect(commandFromItem(result.ast.body.items[1])).toMatchObject({
        kind: 'simpleCommand',
        commandName: { value: 'echo' },
        arguments: [{ raw: 'after' }],
      });
    });

    test('if本体の予約語引数で入れ子を開始しない', () => {
      const source = 'if true; then echo if fi; fi';

      const result = parse(`${source}\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: source.split(' ')[0] + 'Command',
        raw: source,
      });
    });

    test('while本体の予約語引数で入れ子を開始しない', () => {
      const source = 'while false; do echo while done; done';

      const result = parse(`${source}\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: source.split(' ')[0] + 'Command',
        raw: source,
      });
    });

    test('until本体の予約語引数で入れ子を開始しない', () => {
      const source = 'until true; do echo until done; done';

      const result = parse(`${source}\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: source.split(' ')[0] + 'Command',
        raw: source,
      });
    });

    test('ループ変数のwhileを構文の開始にしない', () => {
      const source = 'for while in one two; do echo done; done';

      const result = parse(`${source}\n`);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
      expect(commandFromItem(result.ast.body.items[0])).toMatchObject({
        kind: source.split(' ')[0] + 'Command',
        raw: source,
      });
    });
  });
});

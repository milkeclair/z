import type { FunctionSnapshot } from '../refreshFunctions/main';
import { projectFileFunctions } from '../refreshFunctions/projection';
import type { FunctionTargets } from '../refreshFunctions/target';
import type { ZshFileHydration } from '../zshHydrator';
import { createZshFileHydration } from '../zshHydrator';
import type { SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { Diagnostics } from '../diagnostics/type';
import type { ResolutionContext, CallScope } from '../diagnostics/calls';
import { analyzeCalls } from '../diagnostics/calls';
import { collectFileFacts } from '../diagnostics/facts';
import { DiagnosticSeverity } from '../vscode_type';
import { protocolRange } from '../connection/ast/cursor';
import { codeArguments } from './arguments';
import { collectIgnoreControls, ignored } from '../diagnostics/controls';
import { createCodeSourceMap, codeRange, textLineStarts } from './sourceMap';
import type { CodeSourceMap } from './sourceMap';
import type { DecodedLiteral } from './literal';

export type CodeProgram = {
  readonly file: ZshFileHydration;
  readonly root: ZshFileHydration;
  readonly content: string;
  readonly lineStarts: readonly number[];
  readonly word: WordNode;
  readonly literal: DecodedLiteral;
  readonly prefix: string;
  readonly source: CodeSourceMap;
  readonly localSource: CodeSourceMap;
  readonly targets: FunctionTargets;
  readonly parent?: CodeProgram;
  readonly complete: boolean;
  readonly depth: number;
};

type Pending = {
  readonly file: ZshFileHydration;
  readonly calls: readonly SimpleCommandNode[];
  readonly context: ResolutionContext;
  readonly scopes: readonly CallScope[];
  readonly program?: CodeProgram;
  readonly depth: number;
};

const MAX_CODE_DEPTH = 32;
const MAX_CODE_TEXT = 1024 * 1024;

/** 内側の定義を公開索引へ加えず、表示位置だけを元のファイルへ対応付ける。 */
function programTargets(file: ZshFileHydration, source: CodeSourceMap, name: string): FunctionTargets {
  return new Map([...projectFileFunctions(file).targets].map(([key, targets]) => [key,
    targets.map(target => ({ ...target, source, info: {
      ...target.info, file: name, line: codeRange(source, target.nameNode.range).start.line + 1,
    } })),
  ]));
}

/** 明示スタックと文字数上限を共有し、診断と編集に使う埋め込みASTを一度だけ生成する。 */
export function analyzeEmbeddedCode(snapshot: FunctionSnapshot, file: ZshFileHydration,
  calls: readonly SimpleCommandNode[], context: ResolutionContext,
  limits: { readonly maxDepth?: number; readonly maxText?: number } = {}): {
    readonly diagnostics: readonly Diagnostics[]; readonly programs: readonly CodeProgram[];
  } {
  const diagnostics: Diagnostics[] = [];
  const programs: CodeProgram[] = [];
  const pending: Pending[] = [{ file, calls, context, scopes: [], depth: 0 }];
  let textBudget = limits.maxText ?? MAX_CODE_TEXT;
  const maxDepth = limits.maxDepth ?? MAX_CODE_DEPTH;
  while (pending.length) {
    const current = pending.pop();
    if (!current) break;
    const sourceMap = current.program?.source;
    const complete = current.program?.complete ?? true;
    const ignores = sourceMap ? collectIgnoreControls(current.file) : undefined;
    const analysis = analyzeCalls(snapshot, current.file, current.calls, current.context, {
      scopes: current.scopes, mapRange: sourceMap ? range => codeRange(sourceMap, range) : undefined,
      ignores,
    });
    if (complete) {
      for (const diagnostic of analysis.diagnostics) diagnostics.push(diagnostic);
    }

    for (const [command, target] of analysis.targets) {
      const batch = codeArguments(command, target, current.context, textBudget, true);
      textBudget -= batch.inspected;
      for (const argument of batch.arguments) {
        if (argument.kind === 'limit' || current.depth >= maxDepth) {
          if (complete && (!ignores || !ignored(ignores, argument.word.range.start.line, 'embedded-analysis-limit'))) diagnostics.push({
            severity: DiagnosticSeverity.Warning, code: 'embedded-analysis-limit', source: 'z-ls',
            range: protocolRange(sourceMap ? codeRange(sourceMap, argument.word.range) : argument.word.range),
            message: 'Embedded code exceeds the analysis budget.',
          });
          continue;
        }

        const source = createCodeSourceMap(argument.word, argument.source, sourceMap);
        const localSource = sourceMap ? createCodeSourceMap(argument.word, argument.source) : source;
        const child = createZshFileHydration({ sourceFile: file.sourceFile,
          file: current.file.file + '#code:' + argument.word.range.start.offset, content: argument.source.text });
        const childComplete = complete && !argument.source.unterminated;
        const program: CodeProgram = {
          file: child, root: file, content: argument.source.text, lineStarts: textLineStarts(argument.source.text), word: argument.word,
          literal: argument.source, prefix: argument.prefix, source, localSource,
          targets: programTargets(child, source, file.file), parent: current.program,
          complete: childComplete, depth: current.depth + 1,
        };
        programs.push(program);

        if (childComplete) {
          const controls = collectIgnoreControls(child);
          const syntax = [
            ...child.lexerDiagnostics.map(diagnostic => ({ ...diagnostic, source: 'z-ls/lexer' })),
            ...child.parserDiagnostics.map(diagnostic => ({ ...diagnostic, source: 'z-ls/parser' })),
            ...child.hydrationDiagnostics.map(diagnostic => ({ ...diagnostic, source: 'z-ls/documentation' })),
          ];
          for (const diagnostic of syntax) {
            if (ignored(controls, diagnostic.range.start.line, diagnostic.kind)) continue;
            diagnostics.push({ severity: diagnostic.source === 'z-ls/documentation' ? DiagnosticSeverity.Warning : DiagnosticSeverity.Error,
              code: diagnostic.kind, range: protocolRange(codeRange(source, diagnostic.range)), message: diagnostic.message, source: diagnostic.source });
          }
        }

        const facts = collectFileFacts(child);
        const declarations = facts.declarations;
        const inherited = current.context;
        const childContext: ResolutionContext = { ...inherited,
          aliases: declarations.aliases.size ? new Set([...inherited.aliases, ...declarations.aliases]) : inherited.aliases,
          globalAliases: declarations.globalAliases.size ? new Set([...inherited.globalAliases, ...declarations.globalAliases]) : inherited.globalAliases,
          suffixAliases: declarations.suffixAliases.size ? new Set([...inherited.suffixAliases, ...declarations.suffixAliases]) : inherited.suffixAliases,
          autoloads: declarations.autoloads.size ? new Set([...inherited.autoloads, ...declarations.autoloads]) : inherited.autoloads,
          builtins: declarations.builtins.size ? new Set([...inherited.builtins, ...declarations.builtins]) : inherited.builtins };

        pending.push({ file: child, calls: facts.calls, context: childContext, program,
          scopes: [{ file: current.file, offset: argument.word.range.start.offset }, ...current.scopes], depth: current.depth + 1 });
      }
    }
  }
  return { diagnostics, programs };
}

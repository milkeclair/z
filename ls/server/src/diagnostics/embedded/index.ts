import type { FunctionSnapshot } from '../../refreshFunctions/main';
import type { ZshFileHydration } from '../../zshHydrator';
import { createZshFileHydration } from '../../zshHydrator';
import type { SimpleCommandNode } from '../../zshParser/ast';
import type { Diagnostics } from '../type';
import type { ResolutionContext, CallScope } from '../calls';
import { analyzeCalls } from '../calls';
import { collectFileFacts } from '../facts';
import { classCommands } from '../classes';
import { DiagnosticSeverity } from '../../vscode_type';
import { protocolRange } from '../../connection/ast/cursor';
import { codeArguments } from './arguments';
import { collectIgnoreControls, ignored } from '../controls';
import { createCodeSourceMap, codeRange } from './sourceMap';
import type { CodeSourceMap } from './sourceMap';

type Program = {
  readonly file: ZshFileHydration;
  readonly calls: readonly SimpleCommandNode[];
  readonly context: ResolutionContext;
  readonly scopes: readonly CallScope[];
  readonly source?: CodeSourceMap;
  readonly depth: number;
};
const MAX_CODE_DEPTH = 32;
const MAX_CODE_TEXT = 1024 * 1024;

/** 明示スタックとファイルごとの処理上限を使い、コード型を指定した文字列を解析する。 */
export function embeddedCallDiagnostics(snapshot: FunctionSnapshot, file: ZshFileHydration,
  calls: readonly SimpleCommandNode[], context: ResolutionContext,
  limits: { readonly maxDepth?: number; readonly maxText?: number } = {}): readonly Diagnostics[] {
  const diagnostics: Diagnostics[] = [];
  const pending: Program[] = [{ file, calls, context, scopes: [], depth: 0 }];
  let textBudget = limits.maxText ?? MAX_CODE_TEXT;
  const maxDepth = limits.maxDepth ?? MAX_CODE_DEPTH;
  while (pending.length) {
    const program = pending.pop();
    if (!program) break;
    const sourceMap = program.source;
    const ignores = sourceMap ? collectIgnoreControls(program.file) : undefined;
    const analysis = analyzeCalls(snapshot, program.file, program.calls, program.context, {
      scopes: program.scopes, mapRange: sourceMap ? range => codeRange(sourceMap, range) : undefined,
      ignores,
    });
    diagnostics.push(...analysis.diagnostics);
    for (const [command, target] of analysis.targets) {
      const batch = codeArguments(command, target, program.context, textBudget);
      textBudget -= batch.inspected;
      for (const argument of batch.arguments) {
        if (argument.kind === 'limit' || program.depth >= maxDepth) {
          if (!ignores || !ignored(ignores, argument.word.range.start.line, 'embedded-analysis-limit')) diagnostics.push({ severity: DiagnosticSeverity.Warning, code: 'embedded-analysis-limit', source: 'z-ls',
            range: protocolRange(sourceMap ? codeRange(sourceMap, argument.word.range) : argument.word.range),
            message: 'Embedded code exceeds the analysis budget.' });
          continue;
        }
        const source = createCodeSourceMap(argument.word, argument.source, sourceMap);
        const child = createZshFileHydration({ sourceFile: file.sourceFile,
          file: program.file.file + '#code:' + argument.word.range.start.offset, content: argument.source.text });
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
        const facts = collectFileFacts(child);
        const declarations = facts.declarations;
        const inherited = program.context;
        const classFiles = [...inherited.classFiles, child.classes];
        const childContext: ResolutionContext = {
          ...inherited,
          classFiles,
          classCommands: classCommands(classFiles),
          aliases: new Set([...inherited.aliases, ...declarations.aliases]),
          globalAliases: new Set([...inherited.globalAliases, ...declarations.globalAliases]),
          suffixAliases: new Set([...inherited.suffixAliases, ...declarations.suffixAliases]),
          autoloads: new Set([...inherited.autoloads, ...declarations.autoloads]),
          builtins: new Set([...inherited.builtins, ...declarations.builtins]),
        };
        pending.push({ file: child, calls: facts.calls, context: childContext, source,
          scopes: [{ file: program.file, offset: argument.word.range.start.offset }, ...program.scopes], depth: program.depth + 1 });
      }
    }
  }
  return diagnostics;
}

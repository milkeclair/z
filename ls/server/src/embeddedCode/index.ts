import { appendItems, collectArray } from '../util/collections';
import { protocolRange } from '../connection/ast/cursor';
import type { CallScope, ResolutionContext } from '../diagnostics/calls';
import { analyzeCalls } from '../diagnostics/calls';
import type { IgnoreControls } from '../diagnostics/controls';
import { collectIgnoreControls, ignored } from '../diagnostics/controls';
import type { Declarations } from '../diagnostics/facts';
import { collectFileFacts } from '../diagnostics/facts';
import type { Diagnostics } from '../diagnostics/type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { projectFileFunctions } from '../refreshFunctions/projection';
import type { FunctionTargets } from '../refreshFunctions/target';
import { again, done, loop } from '../util/loop';
import { DiagnosticSeverity } from '../vscode_type';
import type { ZshFileHydration } from '../zshHydrator';
import { createZshFileHydration } from '../zshHydrator';
import type { SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { CodeArgument } from './arguments';
import { codeArguments } from './arguments';
import type { DecodedLiteral } from './literal';
import type { CodeSourceMap } from './sourceMap';
import { codeRange, createCodeSourceMap, textLineStarts } from './sourceMap';

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
function programTargets(
  file: ZshFileHydration,
  source: CodeSourceMap,
  name: string,
): FunctionTargets {
  return new Map(
    [...projectFileFunctions(file).targets].map(([key, targets]) => [
      key,
      targets.map((target) => ({
        ...target,
        source,
        info: {
          ...target.info,
          file: name,
          line: codeRange(source, target.nameNode.range).start.line + 1,
        },
      })),
    ]),
  );
}

type AnalysisProgress = {
  readonly pending: ReadonlyArray<Pending>;
  readonly textBudget: number;
  readonly diagnostics: ReadonlyArray<Diagnostics>;
  readonly programs: ReadonlyArray<CodeProgram>;
};

type ExpansionContext = {
  readonly root: ZshFileHydration;
  readonly current: Pending;
  readonly maxDepth: number;
  readonly complete: boolean;
  readonly sourceMap: CodeSourceMap | undefined;
  readonly ignores: IgnoreControls | undefined;
};

function embeddedSyntax(program: CodeProgram): readonly Diagnostics[] {
  if (!program.complete) {
    return [];
  }

  const child = program.file;
  const controls = collectIgnoreControls(child);
  const syntax = [
    ...child.lexerDiagnostics.map((diagnostic) => ({ ...diagnostic, source: 'z-ls/lexer' })),
    ...child.parserDiagnostics.map((diagnostic) => ({ ...diagnostic, source: 'z-ls/parser' })),
    ...child.hydrationDiagnostics.map((diagnostic) => ({
      ...diagnostic,
      source: 'z-ls/documentation',
    })),
  ];

  return syntax
    .filter((diagnostic) => !ignored(controls, diagnostic.range.start.line, diagnostic.kind))
    .map((diagnostic): Diagnostics => ({
      severity:
        diagnostic.source === 'z-ls/documentation'
          ? DiagnosticSeverity.Warning
          : DiagnosticSeverity.Error,
      code: diagnostic.kind,
      range: protocolRange(codeRange(program.source, diagnostic.range)),
      message: diagnostic.message,
      source: diagnostic.source,
    }));
}

function inheritedContext(
  parent: ResolutionContext,
  declarations: Declarations,
): ResolutionContext {
  return {
    ...parent,
    aliases: declarations.aliases.size
      ? new Set([...parent.aliases, ...declarations.aliases])
      : parent.aliases,
    globalAliases: declarations.globalAliases.size
      ? new Set([...parent.globalAliases, ...declarations.globalAliases])
      : parent.globalAliases,
    suffixAliases: declarations.suffixAliases.size
      ? new Set([...parent.suffixAliases, ...declarations.suffixAliases])
      : parent.suffixAliases,
    autoloads: declarations.autoloads.size
      ? new Set([...parent.autoloads, ...declarations.autoloads])
      : parent.autoloads,
    builtins: declarations.builtins.size
      ? new Set([...parent.builtins, ...declarations.builtins])
      : parent.builtins,
  };
}

function expandArgument(
  progress: AnalysisProgress,
  argument: CodeArgument,
  context: ExpansionContext,
): AnalysisProgress {
  const { current, root, maxDepth, complete, sourceMap, ignores } = context;

  if (argument.kind === 'limit' || current.depth >= maxDepth) {
    const report =
      complete &&
      (!ignores || !ignored(ignores, argument.word.range.start.line, 'embedded-analysis-limit'));

    return report
      ? {
          ...progress,
          diagnostics: appendItems(progress.diagnostics, {
            severity: DiagnosticSeverity.Warning,
            code: 'embedded-analysis-limit',
            source: 'z-ls',
            range: protocolRange(
              sourceMap ? codeRange(sourceMap, argument.word.range) : argument.word.range,
            ),
            message: 'Embedded code exceeds the analysis budget.',
          }),
        }
      : progress;
  }

  const source = createCodeSourceMap(argument.word, argument.source, sourceMap);
  const localSource = sourceMap ? createCodeSourceMap(argument.word, argument.source) : source;
  const child = createZshFileHydration({
    sourceFile: root.sourceFile,
    file: current.file.file + '#code:' + argument.word.range.start.offset,
    content: argument.source.text,
  });
  const program: CodeProgram = {
    file: child,
    root,
    content: argument.source.text,
    lineStarts: textLineStarts(argument.source.text),
    word: argument.word,
    literal: argument.source,
    prefix: argument.prefix,
    source,
    localSource,
    targets: programTargets(child, source, root.file),
    parent: current.program,
    complete: complete && !argument.source.unterminated,
    depth: current.depth + 1,
  };
  const facts = collectFileFacts(child);
  const pending: Pending = {
    file: child,
    calls: facts.calls,
    context: inheritedContext(current.context, facts.declarations),
    program,
    scopes: [{ file: current.file, offset: argument.word.range.start.offset }, ...current.scopes],
    depth: current.depth + 1,
  };

  return {
    ...progress,
    programs: appendItems(progress.programs, program),
    diagnostics: progress.diagnostics.concat(embeddedSyntax(program)),
    pending: appendItems(progress.pending, pending),
  };
}

/** 明示スタックと文字数上限を共有し、診断と編集に使う埋め込みASTを一度だけ生成する。 */
export function analyzeEmbeddedCode(
  snapshot: FunctionSnapshot,
  file: ZshFileHydration,
  calls: readonly SimpleCommandNode[],
  context: ResolutionContext,
  limits: {
    readonly maxDepth?: number;
    readonly maxText?: number;
  } = {},
): {
  readonly diagnostics: readonly Diagnostics[];
  readonly programs: readonly CodeProgram[];
} {
  const maxDepth = limits.maxDepth ?? MAX_CODE_DEPTH;
  const initial: AnalysisProgress = {
    pending: collectArray([{ file, calls, context, scopes: [], depth: 0 }]),
    diagnostics: collectArray(),
    programs: collectArray(),
    textBudget: limits.maxText ?? MAX_CODE_TEXT,
  };

  return loop<
    AnalysisProgress,
    {
      readonly diagnostics: readonly Diagnostics[];
      readonly programs: readonly CodeProgram[];
    }
  >(initial, (state) => {
    const current = state.pending.at(-1);

    if (!current) {
      return done({ diagnostics: state.diagnostics, programs: state.programs });
    }

    const sourceMap = current.program?.source;
    const complete = current.program?.complete ?? true;
    const ignores = sourceMap ? collectIgnoreControls(current.file) : undefined;
    const analysis = analyzeCalls(snapshot, current.file, current.calls, current.context, {
      scopes: current.scopes,
      mapRange: sourceMap ? (range) => codeRange(sourceMap, range) : undefined,
      ignores,
    });
    const reported: AnalysisProgress = {
      ...state,
      pending: state.pending.slice(0, -1),
      diagnostics: complete ? state.diagnostics.concat(analysis.diagnostics) : state.diagnostics,
    };
    const next = [...analysis.targets].reduce((progress, [command, target]) => {
      const batch = codeArguments(command, target, current.context, progress.textBudget, true);
      const bounded = { ...progress, textBudget: progress.textBudget - batch.inspected };

      return batch.arguments.reduce(
        (previous, argument) =>
          expandArgument(previous, argument, {
            root: file,
            current,
            maxDepth,
            sourceMap,
            complete,
            ignores,
          }),
        bounded,
      );
    }, reported);

    return again(next);
  });
}

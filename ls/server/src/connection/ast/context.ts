import { addValue, makeSet, takeWhile, unionValues } from '../../util/collections';
import { pathToFileURL } from 'url';
import type { CodeProgram } from '../../embeddedCode';
import type { FuncArg } from '../../getFunctions/type';
import type { FunctionSnapshot } from '../../refreshFunctions/main';
import type { FunctionTarget } from '../../refreshFunctions/target';
import { literalWord } from '../../refreshFunctions/word';
import { again, done, loop } from '../../util/loop';
import type { FunctionDefinitionNode, WordNode } from '../../zshParser/ast';
import type { Cursor } from './cursor';
import { callAt, functionCommand, inside } from './cursor';
import { namedKey } from './word';

function closest(candidates: readonly FunctionTarget[], offset: number): FunctionTarget | null {
  return (
    candidates.findLast((target) => target.nameNode.range.start.offset <= offset) ??
    candidates[0] ??
    null
  );
}

export function resolveFunction(
  snapshot: FunctionSnapshot,
  name: string,
  cursor: Pick<Cursor, 'file' | 'offset' | 'program' | 'targets'>,
): FunctionTarget | null {
  type Search = {
    readonly program: CodeProgram | undefined;
    readonly offset: number;
  };

  return loop<Search, FunctionTarget | null>(
    { program: cursor.program, offset: cursor.offset },
    (current) => {
      if (current.program) {
        const local = closest(current.program.targets.get(name) ?? [], current.offset);

        return local
          ? done(local)
          : again({
              program: current.program.parent,
              offset: current.program.word.range.start.offset,
            });
      }

      const own = closest(cursor.targets?.get(name) ?? [], current.offset);

      if (own) {
        return done(own);
      }

      const candidates = snapshot.targets.get(name) ?? [];
      const uri = fileUri(cursor.file.sourceFile);
      const local = candidates.filter((candidate) => candidate.uri === uri);

      return done(closest(local, current.offset) ?? candidates[0] ?? null);
    },
  );
}

/** 内側のローカルな名前を候補へ加え、公開索引は変更しない。 */
export function candidateNames(snapshot: FunctionSnapshot, cursor: Cursor): ReadonlySet<string> {
  type Names = {
    readonly program: CodeProgram | undefined;
    readonly names: ReadonlySet<string>;
  };

  const initial: Names = {
    program: cursor.program,
    names: unionValues(makeSet(snapshot.targets.keys()), cursor.targets?.keys() ?? []),
  };

  return loop<Names, ReadonlySet<string>>(initial, (current) =>
    current.program
      ? again({
          program: current.program.parent,
          names: unionValues(current.names, current.program.targets.keys()),
        })
      : done(new Set(current.names)),
  );
}

function fileUri(sourceFile: string): string {
  return pathToFileURL(sourceFile).href;
}

export function declarationAt(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  for (const node of cursor.path.toReversed()) {
    if (node.kind !== 'functionDefinition') {
      continue;
    }

    const word = node.names.find((name) => inside(name.range, cursor.offset));

    if (!word) {
      return null;
    }

    const name = literalWord(word);

    return name
      ? ((cursor.program?.targets ?? cursor.targets ?? snapshot.targets)
          .get(name)
          ?.find((target) => target.nameNode === word) ?? null)
      : null;
  }

  return null;
}

export function ownerFunction(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  const definition = cursor.path
    .toReversed()
    .find((node): node is FunctionDefinitionNode => node.kind === 'functionDefinition');

  if (!definition) {
    return null;
  }

  for (const word of definition.names) {
    const name = literalWord(word);
    const target = name
      ? (cursor.program?.targets ?? cursor.targets ?? snapshot.targets)
          .get(name)
          ?.find((candidate) => candidate.definition === definition)
      : null;

    if (target) {
      return target;
    }
  }

  return null;
}

export function calledFunction(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  const command = callAt(cursor);

  if (!command?.commandName || !functionCommand(command)) {
    return null;
  }

  const name = literalWord(command.commandName.word);

  return name ? resolveFunction(snapshot, name, cursor) : null;
}

export function targetAtName(
  snapshot: FunctionSnapshot,
  cursor: Cursor,
): {
  readonly target: FunctionTarget;
  readonly word: WordNode;
} | null {
  const declared = declarationAt(snapshot, cursor);

  if (declared) {
    return { target: declared, word: declared.nameNode };
  }

  const command = callAt(cursor);
  const word = command?.commandName?.word;

  if (!word || !inside(word.range, cursor.offset)) {
    return null;
  }

  const target = calledFunction(snapshot, cursor);

  return target ? { target, word } : null;
}

export function argumentAt(cursor: Cursor): WordNode | null {
  return callAt(cursor)?.arguments.find((word) => inside(word.range, cursor.offset)) ?? null;
}

export function activeArgument(
  target: FunctionTarget,
  cursor: Cursor,
): {
  readonly argument: FuncArg;
  readonly index: number;
} | null {
  const command = callAt(cursor);

  if (!command?.commandName || cursor.offset <= command.commandName.range.end.offset) {
    return null;
  }

  const current = argumentAt(cursor);
  const args = target.info.args;
  const key = current
    ? (namedKey(current) ?? (!current.quoted ? literalWord(current) : null))
    : null;
  const named = args.findIndex((arg) => arg.isNamed && arg.name === key);

  if (named >= 0) {
    return { argument: args[named], index: named };
  }

  const supplied = takeWhile(
    Iterator.from(command.arguments),
    (word) => word !== current && word.range.start.offset < cursor.offset,
  ).reduce(
    (previous, word) => {
      const candidate = namedKey(word);

      return candidate && args.some((argument) => argument.isNamed && argument.name === candidate)
        ? { ...previous, used: addValue(previous.used, candidate) }
        : { ...previous, position: previous.position + 1 };
    },
    { used: makeSet<string>(), position: 1 },
  );
  const positional = args.findIndex(
    (argument) => !argument.isNamed && argument.position === supplied.position,
  );
  const rest =
    positional >= 0
      ? positional
      : args.findIndex(
          (argument) => !argument.isNamed && (argument.name === '@' || argument.name === '*'),
        );
  const index =
    rest >= 0
      ? rest
      : args.findIndex((argument) => argument.isNamed && !supplied.used.has(argument.name));

  return index < 0 ? null : { argument: args[index], index };
}

import { pathToFileURL } from 'url';
import type { FunctionSnapshot } from '../../refreshFunctions/main';
import type { FunctionTarget } from '../../refreshFunctions/target';
import type { FunctionDefinitionNode, WordNode } from '../../zshParser/ast';
import type { FuncArg } from '../../getFunctions/type';
import { literalWord } from '../../refreshFunctions/word';
import { namedKey } from './word';
import { callAt, functionCommand, inside } from './cursor';
import type { Cursor } from './cursor';

export function resolveFunction(snapshot: FunctionSnapshot, name: string, cursor: Cursor): FunctionTarget | null {
  const candidates = snapshot.targets.get(name) ?? [];
  const uri = fileUri(cursor.file.sourceFile);
  let local: FunctionTarget | null = null;
  let nearest: FunctionTarget | null = null;
  for (const candidate of candidates) {
    if (candidate.uri !== uri) continue;
    local ??= candidate;
    const start = candidate.nameNode.range.start.offset;
    if (start <= cursor.offset && (!nearest || start > nearest.nameNode.range.start.offset)) nearest = candidate;
  }
  return nearest ?? local ?? candidates[0] ?? null;
}

function fileUri(sourceFile: string): string {
  return pathToFileURL(sourceFile).href;
}

export function declarationAt(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  for (const node of [...cursor.path].reverse()) {
    if (node.kind !== 'functionDefinition') continue;
    const word = node.names.find(name => inside(name.range, cursor.offset));
    if (!word) return null;
    const name = literalWord(word);
    return name ? snapshot.targets.get(name)?.find(target => target.nameNode === word) ?? null : null;
  }
  return null;
}

export function ownerFunction(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  const definition = [...cursor.path].reverse().find((node): node is FunctionDefinitionNode => node.kind === 'functionDefinition');
  if (!definition) return null;
  for (const word of definition.names) {
    const name = literalWord(word);
    const target = name ? snapshot.targets.get(name)?.find(candidate => candidate.definition === definition) : null;
    if (target) return target;
  }
  return null;
}

export function calledFunction(snapshot: FunctionSnapshot, cursor: Cursor): FunctionTarget | null {
  const command = callAt(cursor);
  if (!command?.commandName || !functionCommand(command)) return null;
  const name = literalWord(command.commandName.word);
  return name ? resolveFunction(snapshot, name, cursor) : null;
}

export function targetAtName(snapshot: FunctionSnapshot, cursor: Cursor): {
  readonly target: FunctionTarget; readonly word: WordNode;
} | null {
  const declared = declarationAt(snapshot, cursor);
  if (declared) return { target: declared, word: declared.nameNode };
  const command = callAt(cursor);
  const word = command?.commandName?.word;
  if (!word || !inside(word.range, cursor.offset)) return null;
  const target = calledFunction(snapshot, cursor);
  return target ? { target, word } : null;
}

export function argumentAt(cursor: Cursor): WordNode | null {
  return callAt(cursor)?.arguments.find(word => inside(word.range, cursor.offset)) ?? null;
}

export function activeArgument(target: FunctionTarget, cursor: Cursor): { readonly argument: FuncArg; readonly index: number } | null {
  const command = callAt(cursor);
  if (!command?.commandName || cursor.offset <= command.commandName.range.end.offset) return null;
  const current = argumentAt(cursor);
  const args = target.info.args;
  const key = current ? namedKey(current) ?? (!current.quoted ? literalWord(current) : null) : null;
  const named = args.findIndex(arg => arg.isNamed && arg.name === key);
  if (named >= 0) return { argument: args[named], index: named };
  const used = new Set<string>();
  let position = 1;
  for (const word of command.arguments) {
    if (word === current || word.range.start.offset >= cursor.offset) break;
    const candidate = namedKey(word);
    if (candidate && args.some(arg => arg.isNamed && arg.name === candidate)) used.add(candidate);
    else position += 1;
  }
  let index = args.findIndex(arg => !arg.isNamed && arg.position === position);
  if (index < 0) index = args.findIndex(arg => !arg.isNamed && (arg.name === '@' || arg.name === '*'));
  if (index < 0) index = args.findIndex(arg => arg.isNamed && !used.has(arg.name));
  return index < 0 ? null : { argument: args[index], index };
}

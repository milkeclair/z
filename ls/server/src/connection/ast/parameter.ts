import type { AstNode, SimpleCommandNode, WordNode } from '../../zshParser/ast';
import { walk } from '../../zshParser/ast';
import type { FuncArg } from '../../getFunctions/type';
import type { FunctionTarget } from '../../refreshFunctions/target';
import type { Cursor } from './cursor';
import { inside } from './cursor';
import { literalWord } from '../../refreshFunctions/word';

function parameterName(raw: string): string | null {
  if (!raw.startsWith('$')) return null;
  const name = raw[1] === '{' && raw.endsWith('}') ? raw.slice(2, -1) : raw.slice(1);
  if (name === '@' || name === '*' || name.length > 0 && [...name].every(char => char >= '0' && char <= '9')) return name;
  const bracket = name.indexOf('[');
  if (bracket > 0 && name.endsWith(']') && [...name.slice(0, bracket)].every((char, index) =>
    char === '_' || char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' || index > 0 && char >= '0' && char <= '9')) {
    const key = name.slice(bracket + 1, -1);
    if (key.length && [...key].every(char => char === '_' ||
      char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' || char >= '0' && char <= '9')) return key;
  }
  return null;
}

function argumentByName(target: FunctionTarget, name: string | null): FuncArg | null {
  if (name === null) return null;
  return target.info.args.find(arg => arg.isNamed ? arg.name === name :
    name === '@' || name === '*' ? arg.name === name : arg.position === Number(name)) ?? null;
}

function initializer(word: WordNode): string | null {
  const expansions = word.parts.filter(part => part.kind === 'variableReference' || part.kind === 'parameterExpansion');
  if (expansions.length !== 1) return null;
  const expansion = expansions[0];
  const start = expansion.range.start.offset - word.range.start.offset;
  const end = expansion.range.end.offset - word.range.start.offset;
  const before = word.raw.slice(0, start);
  const after = word.raw.slice(end);
  const suffix = before === '"' && after.endsWith('"') ? after.slice(0, -1) : after;
  if (!(before === '' || before === '"') || suffix !== '' &&
    !(expansion.kind === 'variableReference' && suffix.startsWith('[') && suffix.endsWith(']'))) return null;
  if (before === '"' && !after.endsWith('"')) return null;
  return expansion.kind === 'parameterExpansion' ? expansion.raw : '$' + expansion.name.value + suffix;
}

function namedReply(command: SimpleCommandNode, cursor: Cursor): string | null {
  const sublist = [...cursor.path].reverse().find(node => node.kind === 'sublist' && node.range.start.offset <= command.range.start.offset);
  if (!sublist || sublist.kind !== 'sublist') return null;
  const index = sublist.rest.findIndex(rest => rest.pipeline.first === command);
  if (index < 0 || sublist.rest[index].operator.type !== 'andIf') return null;
  const preceding = index === 0 ? sublist.first : sublist.rest[index - 1].pipeline;
  if (preceding.rest.length || preceding.first.kind !== 'simpleCommand') return null;
  const previous = preceding.first;
  if (!previous.commandName || literalWord(previous.commandName.word) !== 'z.arg.named') return null;
  return previous.arguments[0] ? literalWord(previous.arguments[0]) : null;
}

function aliasArgument(target: FunctionTarget, cursor: Cursor, name: string): FuncArg | null {
  let result: FuncArg | null = null;
  const allowed = new Set(cursor.path);
  const ancestors: AstNode[] = [];
  walk(target.definition.body, (node, depth) => {
    ancestors.length = depth;
    ancestors.push(node);
    if (node.range.start.offset >= cursor.offset) return 'skip';
    if (node.kind === 'functionDefinition') return 'skip';
    if ((node.kind === 'list' || node.kind === 'subshellCommand' ||
      node.kind === 'commandSubstitution' || node.kind === 'processSubstitution') && !allowed.has(node)) return 'skip';
    if (node.kind !== 'simpleCommand') return;
    const declaration = node.semantic.role === 'declaration' ? node.semantic.declaration : null;
    const assignments = declaration?.assignments ?? (node.commandName ? [] : node.prefixAssignments);
    for (const assignment of assignments) {
      if (assignment.name.value !== name || assignment.range.start.offset >= cursor.offset) continue;
      const raw = assignment.value ? initializer(assignment.value.value) : null;
      const key = raw === '$REPLY' ? namedReply(node, { ...cursor, path: ancestors }) : raw ? parameterName(raw) : null;
      result = assignment.operator === '=' && !assignment.subscript ? argumentByName(target, key) : null;
    }
    if (declaration?.names.some(variable => variable.value === name)) result = null;
  });
  return result;
}

export function parameterArgument(target: FunctionTarget, cursor: Cursor): FuncArg | null {
  for (const node of [...cursor.path].reverse()) {
    if (!inside(node.range, cursor.offset)) continue;
    if (node.kind === 'parameterExpansion') {
      const direct = argumentByName(target, parameterName(node.raw));
      if (direct) return direct;
      const name = node.raw[1] === '{' && node.raw.endsWith('}') ? node.raw.slice(2, -1) : '';
      const identifier = name.length > 0 && [...name].every((char, index) =>
        char === '_' || char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' ||
        index > 0 && char >= '0' && char <= '9');
      return identifier ? aliasArgument(target, cursor, name) : null;
    }
    if (node.kind === 'variableReference') return aliasArgument(target, cursor, node.name.value);
  }
  return null;
}

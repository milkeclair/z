import type { Position } from 'vscode-languageserver/node';
import { codeEdit } from '../embeddedCode/edit';
import { textPosition } from '../embeddedCode/sourceMap';
import { targetRange } from '../refreshFunctions/target';
import { literalWord } from '../refreshFunctions/word';
import { CompletionItem, CompletionItemKind, CompletionParams } from '../vscode_type';
import type { SourceRange, Token } from '../zshParser/lexer';
import { candidateNames, resolveFunction } from './ast/context';
import type { Cursor } from './ast/cursor';
import { callAt, cursorAt, functionCommand, inside, protocolRange } from './ast/cursor';
import { commandInsertion } from './ast/word';
import type { LanguageFeatureRequest } from './type';

export function zCompletion({
  params,
  documents,
  snapshot,
  showPrivateFunctions,
  programs,
}: LanguageFeatureRequest<CompletionParams> & { readonly showPrivateFunctions: boolean }):
  | CompletionItem[]
  | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) {
    return null;
  }
  const requestOffset = document.offsetAt(params.position);
  const cursor = cursorAt(snapshot, document, requestOffset, programs);
  if (!cursor) {
    return [];
  }
  const completion = completionAtCursor(cursor, params.position);
  if (!completion) {
    return [];
  }
  const { prefix, range } = completion;
  return [...candidateNames(snapshot, cursor)].flatMap((name): CompletionItem[] => {
    if (
      !name.startsWith(prefix) ||
      (!showPrivateFunctions && name.split('.').some((segment) => segment.startsWith('_')))
    ) {
      return [];
    }
    const target = resolveFunction(snapshot, name, cursor);
    if (!target) {
      return [];
    }
    const edit = cursor.program
      ? codeEdit(cursor.program, range, commandInsertion(name))
      : { range, newText: commandInsertion(name) };
    if (
      edit.range.start.line !== edit.range.end.line ||
      edit.range.start.offset > requestOffset ||
      edit.range.end.offset < requestOffset
    ) {
      return [];
    }
    return [
      {
        label: name,
        kind: CompletionItemKind.Function,
        data: {
          file: target.info.file,
          line: target.info.line,
          args: target.info.args,
          uri: target.uri,
          name,
          offset: targetRange(target).start.offset,
          ...(target.source || cursor.targets?.get(name)?.includes(target) ? { local: true } : {}),
        },
        textEdit: { range: protocolRange(edit.range), newText: edit.newText },
      },
    ];
  });
}

const COMMAND_SEPARATORS = new Set([
  'semicolon',
  'andIf',
  'orIf',
  'pipe',
  'pipeErr',
  'background',
  'backgroundPipe',
  'backgroundBang',
  'leftBrace',
  'leftParen',
]);
const COMMAND_KEYWORDS = new Set([
  'if',
  'then',
  'elif',
  'else',
  'while',
  'until',
  'do',
  'time',
  'coproc',
]);

function isCommandSeparator(token: Token | null): boolean {
  return (
    token?.kind === 'newline' ||
    (token?.kind === 'operator' && COMMAND_SEPARATORS.has(token.operatorKind ?? ''))
  );
}

function followsCommandKeyword(cursor: Cursor): boolean {
  const token = cursor.token;
  return (
    token?.kind === 'word' &&
    cursor.offset >= token.range.end.offset &&
    !token.quoted &&
    COMMAND_KEYWORDS.has(token.value)
  );
}

function startsSubstitutionBody(cursor: Cursor): boolean {
  const substitution = cursor.path.findLast(
    (node) => node.kind === 'commandSubstitution' || node.kind === 'processSubstitution',
  );
  if (!substitution?.body) {
    return false;
  }
  return (
    cursor.offset >= substitution.body.range.start.offset &&
    cursor.offset <=
      (substitution.body.items[0]?.range.start.offset ?? substitution.body.range.end.offset)
  );
}

function insideCompoundHeader(cursor: Cursor): boolean {
  return cursor.path.some((node) => {
    switch (node.kind) {
      case 'forCommand':
      case 'selectCommand':
      case 'foreachCommand':
        return cursor.offset < node.body.range.start.offset;
      case 'caseCommand':
        return !node.arms.some(
          (arm) =>
            arm.body.range.start.offset <= cursor.offset &&
            cursor.offset <= arm.body.range.end.offset,
        );
      default:
        return false;
    }
  });
}

function canStartCommand(cursor: Cursor): boolean {
  if (startsSubstitutionBody(cursor)) {
    return true;
  }
  const keyword = followsCommandKeyword(cursor);
  const token = cursor.token;
  if (token && token.kind !== 'eof' && !isCommandSeparator(token) && !keyword) {
    return false;
  }
  const insideWord = cursor.path.some(
    (node) =>
      node.kind === 'word' ||
      node.kind === 'assign' ||
      node.kind === 'redirect' ||
      node.kind === 'precommandModifier' ||
      node.kind === 'arithmeticExpansion',
  );
  return !insideWord && (keyword || !insideCompoundHeader(cursor));
}

function completionAtCursor(
  cursor: Cursor,
  requestPosition: Position,
): { readonly prefix: string; readonly range: SourceRange } | null {
  const call = callAt(cursor);
  const word = call?.commandName?.word;
  if (word && inside(word.range, cursor.offset)) {
    if (!functionCommand(call) || word.range.start.line !== word.range.end.line) {
      return null;
    }
    const prefix = literalWord(word, cursor.offset - word.range.start.offset);
    return prefix === null ? null : { prefix, range: word.range };
  }
  if (!canStartCommand(cursor)) {
    return null;
  }
  const position = cursor.program
    ? textPosition(cursor.program.lineStarts, cursor.offset)
    : { ...requestPosition, offset: cursor.offset };
  return { prefix: '', range: { start: position, end: position } };
}

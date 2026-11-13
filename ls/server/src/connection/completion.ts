import { CompletionItem, CompletionParams, TextDocuments, TextDocument, CompletionItemKind } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { cursorAt, callAt, functionCommand, inside, protocolRange } from './ast/cursor';
import { resolveFunction } from './ast/context';
import { commandInsertion } from './ast/word';
import { literalWord } from '../refreshFunctions/word';

export function zCompletion({
  params, documents, snapshot, showPrivateFunctions,
}: {
  params: CompletionParams; documents: Pick<TextDocuments<TextDocument>, 'get'>;
  snapshot: FunctionSnapshot; showPrivateFunctions: boolean;
}): CompletionItem[] | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;
  const offset = document.offsetAt(params.position);
  const cursor = cursorAt(snapshot, document, offset);
  if (!cursor) return [];
  const call = callAt(cursor);
  const word = call?.commandName?.word;
  let prefix = '';
  let range = { start: params.position, end: params.position };
  if (word && inside(word.range, offset)) {
    if (!functionCommand(call)) return [];
    const value = literalWord(word, offset - word.range.start.offset);
    if (value === null) return [];
    if (word.range.start.line !== word.range.end.line) return [];
    prefix = value;
    range = protocolRange(word.range);
  } else {
    const token = cursor.token;
    const separator = token?.kind === 'newline' ||
      token?.kind === 'operator' && ['semicolon', 'andIf', 'orIf', 'pipe', 'pipeErr',
        'background', 'backgroundPipe', 'backgroundBang', 'leftBrace', 'leftParen'].includes(token.operatorKind ?? '');
    const keyword = token?.kind === 'word' && offset >= token.range.end.offset && !token.quoted &&
      ['if', 'then', 'elif', 'else', 'while', 'until', 'do', 'time', 'coproc'].includes(token.value);
    const substitution = cursor.path.findLast(node => node.kind === 'commandSubstitution' || node.kind === 'processSubstitution');
    const innerStart = substitution && substitution.body &&
      offset >= substitution.body.range.start.offset &&
      offset <= (substitution.body.items[0]?.range.start.offset ?? substitution.body.range.end.offset);
    if (!innerStart) {
      if (token && token.kind !== 'eof' && !separator && !keyword) return [];
      if (cursor.path.some(node => node.kind === 'word' || node.kind === 'assign' ||
        node.kind === 'redirect' || node.kind === 'precommandModifier' || node.kind === 'arithmeticExpansion')) return [];
      if (!keyword && cursor.path.some(node =>
        (node.kind === 'forCommand' || node.kind === 'selectCommand' || node.kind === 'foreachCommand') &&
          offset < node.body.range.start.offset ||
        node.kind === 'caseCommand' && !node.arms.some(arm =>
          arm.body.range.start.offset <= offset && offset <= arm.body.range.end.offset))) return [];
    }
  }
  const items: CompletionItem[] = [];
  for (const name of snapshot.targets.keys()) {
    if (!name.startsWith(prefix) || !showPrivateFunctions && name.split('.').some(segment => segment.startsWith('_'))) continue;
    const target = resolveFunction(snapshot, name, cursor);
    if (!target) continue;
    items.push({
      label: name, kind: CompletionItemKind.Function,
      data: { file: target.info.file, line: target.info.line, args: target.info.args,
        uri: target.uri, name, offset: target.nameNode.range.start.offset },
      textEdit: { range, newText: commandInsertion(name) },
    });
  }
  return items;
}

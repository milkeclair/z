import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import type {
  CommandNode,
  ListItemNode,
  SimpleCommandNode,
  SublistNode,
} from '../../../src/zshParser/ast';

export const TestSourceFile = 'test.zsh';

export function parse(input: string) {
  const tokenized = Lexer.tokenize(input, { sourceFile: TestSourceFile });

  return Parser.parse(tokenized.tokens, {
    sourceFile: TestSourceFile,
    path: TestSourceFile,
  });
}

export function commandFromItem(item: ListItemNode | undefined): CommandNode {
  if (!item) {
    throw new Error('listItemがありません');
  } else if (item.sublist.kind !== 'sublist') {
    return item.sublist;
  } else {
    return item.sublist.first.first;
  }
}

export function simpleCommandFromItem(item: ListItemNode | undefined): SimpleCommandNode {
  const command = commandFromItem(item);

  if (command.kind !== 'simpleCommand') {
    throw new Error(`simpleCommandではありません: ${command.kind}`);
  } else {
    return command;
  }
}

export function sublistFromItem(item: ListItemNode | undefined): SublistNode {
  if (!item) {
    throw new Error('listItemがありません');
  } else if (item.sublist.kind !== 'sublist') {
    throw new Error(`sublistではありません: ${item.sublist.kind}`);
  } else {
    return item.sublist;
  }
}

import type { OperatorKind, Token } from '../token';
import type { HereDocRequest } from './heredoc';
import { hereDocDelimiter } from './heredoc';

export type LexicalKind =
  | 'command'
  | 'array'
  | 'word'
  | 'parameter'
  | 'arithmetic'
  | 'math'
  | 'condition';

export type LexicalContext = {
  readonly kind: LexicalKind;
  readonly close: OperatorKind | null;
  readonly previous: Token | null;
  readonly pendingHereDocs: readonly HereDocRequest[];
  readonly awaitingHereDoc: Pick<HereDocRequest, 'operatorOffset' | 'stripTabs'> | null;
  readonly readHereDocs: boolean;
  readonly parent: LexicalContext | null;
};

export function createLexicalContext(): LexicalContext {
  return {
    kind: 'command',
    close: null,
    previous: null,
    pendingHereDocs: [],
    awaitingHereDoc: null,
    readHereDocs: false,
    parent: null,
  };
}

export function isDollarOpen(context: LexicalContext, offset: number): boolean {
  const previous = context.previous;

  return (
    previous?.kind === 'word' &&
    previous.value.endsWith('$') &&
    previous.range.end.offset === offset
  );
}

export function isProcessOpen(context: LexicalContext, offset: number): boolean {
  const previous = context.previous;

  return Boolean(
    previous &&
    previous.range.end.offset === offset &&
    ((previous.operatorKind === 'redirect' && (previous.value === '<' || previous.value === '>')) ||
      (previous.kind === 'word' && (previous.value === '=' || previous.value.endsWith('==')))),
  );
}

function enter(
  context: LexicalContext,
  token: Token,
  kind: LexicalKind,
  close: OperatorKind,
): LexicalContext {
  return {
    ...createLexicalContext(),
    kind,
    close,
    previous: token,
    parent: { ...context, previous: token },
  };
}

function braceContextKind(
  context: LexicalContext,
  dollar: boolean,
  adjacent: boolean,
): LexicalKind {
  if (dollar || context.kind === 'parameter') {
    return 'parameter';
  }

  return adjacent || context.kind === 'word' ? 'word' : 'command';
}

function parenthesisContextKind(
  context: LexicalContext,
  token: Token,
  dollar: boolean,
  adjacent: boolean,
): LexicalKind {
  if (dollar || isProcessOpen(context, token.range.start.offset)) {
    return 'command';
  }

  if (context.kind === 'arithmetic' || context.kind === 'math') {
    return 'math';
  }

  if (adjacent && context.previous?.value.endsWith('=')) {
    return 'array';
  }

  if (
    adjacent ||
    context.kind === 'word' ||
    context.kind === 'array' ||
    context.kind === 'parameter' ||
    context.kind === 'condition'
  ) {
    return 'word';
  }

  return 'command';
}

export function advanceLexicalContext(context: LexicalContext, token: Token): LexicalContext {
  if (context.close === token.operatorKind && context.parent) {
    return { ...context.parent, previous: token };
  }

  const dollar = isDollarOpen(context, token.range.start.offset);
  const adjacent =
    context.previous?.kind === 'word' &&
    context.previous.range.end.offset === token.range.start.offset;

  if (token.operatorKind === 'arithmeticStart') {
    return enter(context, token, 'arithmetic', 'arithmeticEnd');
  }

  if (token.operatorKind === 'conditionStart' && context.kind === 'command') {
    return enter(context, token, 'condition', 'conditionEnd');
  }

  if (token.operatorKind === 'leftBrace') {
    return enter(context, token, braceContextKind(context, dollar, adjacent), 'rightBrace');
  }

  if (token.operatorKind === 'leftParen') {
    return enter(
      context,
      token,
      parenthesisContextKind(context, token, dollar, adjacent),
      'rightParen',
    );
  }

  const base = { ...context, previous: token, readHereDocs: false };

  if (context.kind !== 'command') {
    return base;
  }

  if (token.operatorKind === 'redirect' && (token.value === '<<' || token.value === '<<-')) {
    return {
      ...base,
      awaitingHereDoc: {
        operatorOffset: token.range.start.offset,
        stripTabs: token.value === '<<-',
      },
    };
  }

  const awaiting = context.awaitingHereDoc;

  if (awaiting && token.kind === 'word') {
    return {
      ...base,
      pendingHereDocs: [
        ...context.pendingHereDocs,
        { ...awaiting, ...hereDocDelimiter(token.value, awaiting.stripTabs) },
      ],
      awaitingHereDoc: null,
    };
  }

  if (token.kind === 'newline') {
    return { ...base, readHereDocs: context.pendingHereDocs.length > 0, awaitingHereDoc: null };
  }

  return base;
}

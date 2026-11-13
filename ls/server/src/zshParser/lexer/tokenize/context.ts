import type { OperatorKind, Token } from '../token';
import type { HereDocRequest } from './heredoc';
import { hereDocDelimiter } from './heredoc';

export type LexicalKind = 'command' | 'array' | 'word' | 'parameter' | 'arithmetic' | 'math' | 'condition';
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
  return { kind: 'command', close: null, previous: null, pendingHereDocs: [], awaitingHereDoc: null, readHereDocs: false, parent: null };
}
export function isDollarOpen(context: LexicalContext, offset: number): boolean {
  const previous = context.previous;
  return previous?.kind === 'word' && previous.value.endsWith('$') && previous.range.end.offset === offset;
}
export function isProcessOpen(context: LexicalContext, offset: number): boolean {
  const previous = context.previous;
  return Boolean(previous && previous.range.end.offset === offset &&
    (previous.operatorKind === 'redirect' && (previous.value === '<' || previous.value === '>') ||
      previous.kind === 'word' && (previous.value === '=' || previous.value.endsWith('=='))));
}
function enter(context: LexicalContext, token: Token, kind: LexicalKind, close: OperatorKind): LexicalContext {
  return { ...createLexicalContext(), kind, close, previous: token, parent: { ...context, previous: token } };
}
export function advanceLexicalContext(context: LexicalContext, token: Token): LexicalContext {
  if (context.close === token.operatorKind && context.parent) return { ...context.parent, previous: token };
  const dollar = isDollarOpen(context, token.range.start.offset);
  const adjacent = context.previous?.kind === 'word' && context.previous.range.end.offset === token.range.start.offset;
  if (token.operatorKind === 'arithmeticStart') return enter(context, token, 'arithmetic', 'arithmeticEnd');
  if (token.operatorKind === 'conditionStart' && context.kind === 'command') return enter(context, token, 'condition', 'conditionEnd');
  if (token.operatorKind === 'leftBrace') {
    const kind = dollar || context.kind === 'parameter' ? 'parameter' : adjacent || context.kind === 'word' ? 'word' : 'command';
    return enter(context, token, kind, 'rightBrace');
  }
  if (token.operatorKind === 'leftParen') {
    const kind = dollar || isProcessOpen(context, token.range.start.offset) ? 'command' : context.kind === 'arithmetic' || context.kind === 'math' ? 'math'
      : adjacent && context.previous?.value.endsWith('=') ? 'array'
        : adjacent || context.kind === 'word' || context.kind === 'array' || context.kind === 'parameter' || context.kind === 'condition' ? 'word' : 'command';
    return enter(context, token, kind, 'rightParen');
  }
  let pendingHereDocs = context.pendingHereDocs;
  let awaitingHereDoc = context.awaitingHereDoc;
  let readHereDocs = false;
  if (context.kind === 'command') {
    if (token.operatorKind === 'redirect' && (token.value === '<<' || token.value === '<<-')) {
      awaitingHereDoc = { operatorOffset: token.range.start.offset, stripTabs: token.value === '<<-' };
    } else if (awaitingHereDoc && token.kind === 'word') {
      pendingHereDocs = [...pendingHereDocs, { ...awaitingHereDoc, ...hereDocDelimiter(token.value, awaitingHereDoc.stripTabs) }];
      awaitingHereDoc = null;
    } else if (token.kind === 'newline') {
      readHereDocs = pendingHereDocs.length > 0;
      awaitingHereDoc = null;
    }
  }
  return { ...context, previous: token, pendingHereDocs, awaitingHereDoc, readHereDocs };
}

import { delimitedEnd } from '../../../../../../../lexer/delimiter';
import { isProcessSubstitutionStart } from '../../../../../../word/composite/token';
import { findOperatorEndIndex, findLineBoundaryIndex } from '../opaque/scan';
import { parseCommand } from '../index';
import type {
  CommandNode, CompoundCommandNode, IfBranchNode, CaseArmNode, ListNode, WordNode, ArithmeticExpansionNode,
} from '../../../../../../../ast';
import type { Token } from '../../../../../../../lexer';
import type { ParserContext } from '../../../../../../context';
import type { NodeResult, ParseState } from '../../../../../../state';
import { advanceState, currentToken, skipTrivia, skipInlineTrivia, addDiagnostic, tokenSlice } from '../../../../../../state';
import { rangeFromTokens, enclosingRange, textForRange } from '../../../../../../range';
import { readPostCommandRedirects } from '../../../../../../redirect';
import { readWordNode } from '../../../../../../word/composite';

const reserved = ['if', 'while', 'until', 'for', 'select', 'foreach', 'repeat', 'case'];

export function isCompoundStart(token: Token): boolean {
  return token.kind === 'word' && !token.quoted && reserved.includes(token.value);
}
function isWordStart(state: ParseState): boolean {
  return currentToken(state).kind === 'word' || isProcessSubstitutionStart(state.tokens, state.index);
}
function isWord(token: Token, value: string): boolean {
  return token.kind === 'word' && !token.quoted && token.value === value;
}
function endAt(...words: readonly string[]) {
  return (token: Token): boolean => token.kind === 'eof' || words.some((word) => isWord(token, word));
}
function skipTerms(state: ParseState): ParseState {
  let current = skipTrivia(state);
  while (currentToken(current).kind === 'newline' || currentToken(current).operatorKind === 'semicolon') {
    current = skipTrivia(advanceState(current));
  }
  return current;
}
function takeKeyword(state: ParseState, value: string): { readonly token: Token | null; readonly state: ParseState } {
  const current = skipTrivia(state);
  const token = currentToken(current);
  if (isWord(token, value)) return { token, state: advanceState(current) };
  return { token: null, state: addDiagnostic({ state: current, kind: 'missingCompoundEnd', message: 'Expected ' + value, tokens: [token] }) };
}
function emptyList(state: ParseState): ListNode {
  const position = currentToken(state).range.start;
  return { kind: 'list', range: { start: position, end: position }, items: [] };
}

export function parseCompoundCommand({
  state, context, readPostBodyRedirects,
}: {
  readonly state: ParseState; readonly context: ParserContext; readonly readPostBodyRedirects: boolean;
}): NodeResult<CompoundCommandNode> {
  const syntax = currentToken(state).value;
  const closeWord = syntax === 'if' ? 'fi' : syntax === 'case' ? 'esac' : syntax === 'foreach' ? 'end' : 'done';
  if (syntax === 'repeat' && isWordStart(skipTrivia(advanceState(state)))) {
    const count = readWordNode(skipTrivia(advanceState(state)));
    if (!isWord(currentToken(skipTerms(count.state)), 'do')) return parseShortRepeat(state, context, readPostBodyRedirects);
  }
  const result = parseCompoundWithin(state, context, readPostBodyRedirects, closeWord);
  if (result.node.close !== null || result.state.stopped) return result;
  let boundary = state.index;
  while (state.tokens[boundary] && state.tokens[boundary].kind !== 'newline' && state.tokens[boundary].kind !== 'eof') boundary += 1;
  if (state.tokens[boundary]?.kind === 'eof') return result;
  const at = state.tokens[boundary] ?? state.eof;
  const eof: Token = { ...state.eof, range: { start: at.range.start, end: at.range.start } };
  const window = { ...state, tokens: [...state.tokens.slice(0, boundary), eof], eof };
  const recovered = parseCompoundWithin(window, context, readPostBodyRedirects, closeWord);
  return { node: recovered.node, state: { ...recovered.state, tokens: state.tokens, eof: state.eof, index: boundary } };
}

function parseCompoundWithin(state: ParseState, context: ParserContext, redirects: boolean, closeWord: string): NodeResult<CompoundCommandNode> {
  const open = currentToken(state);
  const syntax = open.value;
  let current = advanceState(state);
  let branches: readonly IfBranchNode[] = [];
  let condition = emptyList(current);
  let body = emptyList(current);
  let elseBody: ListNode | null = null;
  let variables: readonly WordNode[] = [];
  let words: readonly WordNode[] | null = null;
  let arithmetic: ArithmeticExpansionNode | null = null;
  let subject: WordNode | null = null;
  let count: WordNode | null = null;
  let arms: readonly CaseArmNode[] = [];
  if (syntax === 'if') {
    const collected: IfBranchNode[] = [];
    let keyword = open;
    while (true) {
      const start = context.parseNestedList(current, endAt('then', 'fi'));
      const then = takeKeyword(start.state, 'then');
      const result = context.parseNestedList(then.state, endAt('elif', 'else', 'fi'));
      collected.push({
        kind: 'ifBranch', range: { start: keyword.range.start, end: result.node.range.end },
        keyword: keyword.range, condition: start.node, thenKeyword: then.token?.range ?? null, body: result.node,
      });
      current = result.state;
      if (!isWord(currentToken(current), 'elif')) break;
      keyword = currentToken(current);
      current = advanceState(current);
    }
    branches = collected;
    if (isWord(currentToken(current), 'else')) {
      const result = context.parseNestedList(advanceState(current), endAt('fi'));
      elseBody = result.node; current = result.state;
    }
  } else if (syntax === 'while' || syntax === 'until') {
    const start = context.parseNestedList(current, endAt('do', 'done'));
    condition = start.node;
    const doToken = takeKeyword(start.state, 'do');
    const result = context.parseNestedList(doToken.state, endAt('done'));
    body = result.node; current = result.state;
  } else if (syntax === 'case') {
    current = skipTrivia(current);
    if (isWordStart(current)) {
      const word = readWordNode(current); subject = word.node; current = word.state;
    } else current = addDiagnostic({ state: current, kind: 'unexpectedToken', message: 'Expected case subject', tokens: [currentToken(current)] });
    current = skipTerms(takeKeyword(skipTerms(current), 'in').state);
    const collected: CaseArmNode[] = [];
    while (!endAt('esac')(currentToken(current))) {
      const armStart = currentToken(current);
      if (armStart.operatorKind === 'leftParen') current = advanceState(current);
      const patterns: WordNode[] = [];
      while (currentToken(current).kind !== 'eof' && currentToken(current).operatorKind !== 'rightParen') {
        const token = currentToken(current);
        if (isWordStart(current)) {
          const word = readWordNode(current); patterns.push(word.node); current = word.state;
        } else current = advanceState(current);
        current = skipTrivia(current);
      }
      if (patterns.length === 0) current = addDiagnostic({ state: current, kind: 'unexpectedToken', message: 'Expected case pattern', tokens: [currentToken(current)] });
      if (currentToken(current).operatorKind === 'rightParen') current = advanceState(current);
      const result = context.parseNestedList(current, (token) => endAt('esac')(token) ||
        token.operatorKind === 'doubleSemicolon' || token.operatorKind === 'caseFallthrough' || token.operatorKind === 'caseContinue');
      current = result.state;
      const token = currentToken(current);
      const termination = token.value === ';;' || token.value === ';&' || token.value === ';|' ? token.value : null;
      collected.push({
        kind: 'caseArm', range: { start: armStart.range.start, end: termination ? token.range.end : result.node.range.end },
        patterns, body: result.node, terminator: termination ? token.range : null, termination,
      });
      if (!termination) break;
      current = skipTerms(advanceState(current));
    }
    arms = collected;
  } else {
    current = skipTrivia(current);
    if (syntax === 'repeat') {
      if (isWordStart(current)) {
        const word = readWordNode(current); count = word.node; current = word.state;
      } else current = addDiagnostic({ state: current, kind: 'unexpectedToken', message: 'Expected repeat count', tokens: [currentToken(current)] });
    } else if (currentToken(current).operatorKind === 'arithmeticStart') {
      const start = current.index;
      const end = findOperatorEndIndex({ tokens: current.tokens, index: current.index + 1, endOperatorKind: 'arithmeticEnd' });
      if (end === null) current = addDiagnostic({ state: current, kind: 'missingArithmeticEnd', message: 'Missing arithmetic for closing delimiter', tokens: [currentToken(current)] });
      current = { ...current, index: end === null ? findLineBoundaryIndex(current.tokens, current.index + 1) : end + 1 };
      const tokens = tokenSlice(current, start, current.index);
      arithmetic = { kind: 'arithmeticExpansion', range: rangeFromTokens(tokens), raw: tokens.map((token) => token.value).join('') };
      if (end !== null && arithmeticSeparatorCount(arithmetic.raw.slice(2, -2)) !== 2) {
        current = addDiagnostic({ state: current, kind: 'unexpectedToken', message: 'Arithmetic for requires two clause separators', tokens });
      }
    } else {
      const names: WordNode[] = [];
      while (currentToken(current).kind === 'word' && (names.length === 0 || !isWord(currentToken(current), 'in') && !isWord(currentToken(current), 'do'))) {
        const word = readWordNode(current); names.push(word.node); current = skipInlineTrivia(word.state);
      }
      variables = names;
      if (names.length === 0) current = addDiagnostic({ state: current, kind: 'unexpectedToken', message: 'Expected loop variable after ' + syntax, tokens: [currentToken(current)] });
      if (isWord(currentToken(current), 'in') || currentToken(current).operatorKind === 'leftParen' || syntax === 'foreach') {
        const parenthesized = currentToken(current).operatorKind === 'leftParen';
        current = skipTrivia(advanceState(current));
        const values: WordNode[] = [];
        while (currentToken(current).kind !== 'eof' && currentToken(current).kind !== 'newline' &&
          currentToken(current).operatorKind !== 'semicolon' && currentToken(current).operatorKind !== 'rightParen') {
          if (isWordStart(current)) {
            const word = readWordNode(current); values.push(word.node); current = skipInlineTrivia(word.state);
          } else current = advanceState(current);
        }
        words = values;
        if (parenthesized && currentToken(current).operatorKind === 'rightParen') current = advanceState(current);
      }
    }
    current = skipTerms(current);
    if (syntax !== 'foreach') current = takeKeyword(current, 'do').state;
    const result = context.parseNestedList(current, endAt(closeWord));
    body = result.node; current = result.state;
  }
  const close = takeKeyword(current, closeWord);
  const post = redirects ? readPostCommandRedirects(close.state) : { state: close.state, redirects: [] };
  const tokens = tokenSlice(post.state, state.index, post.state.index);
  const headerRange = rangeFromTokens(tokens, open.range);
  const range = enclosingRange(headerRange, post.redirects);
  const base = { range, raw: range.end.offset === headerRange.end.offset ? tokens.map((token) => token.value).join('') : textForRange(state.tokens, range),
    keyword: open.range, close: close.token?.range ?? null, postBodyRedirects: post.redirects };
  const kind = syntax === 'if' ? 'ifCommand' : syntax === 'while' ? 'whileCommand' : syntax === 'until' ? 'untilCommand'
    : syntax === 'case' ? 'caseCommand' : syntax === 'for' ? 'forCommand' : syntax === 'select' ? 'selectCommand'
      : syntax === 'foreach' ? 'foreachCommand' : 'repeatCommand';
  if (kind === 'ifCommand') return { node: { ...base, kind, branches, elseBody }, state: post.state };
  if (kind === 'whileCommand' || kind === 'untilCommand') return { node: { ...base, kind, condition, body }, state: post.state };
  if (kind === 'caseCommand') return { node: { ...base, kind, subject, arms }, state: post.state };
  if (kind === 'repeatCommand') return { node: { ...base, kind, count, body }, state: post.state };
  return { node: { ...base, kind, variables, words, arithmetic, body }, state: post.state };
}

function listFromCommand(command: CommandNode): ListNode {
  const range = command.range;
  return { kind: 'list', range, items: [{ kind: 'listItem', range, terminator: null,
    sublist: { kind: 'sublist', range, rest: [], first: { kind: 'pipeline', range,
      timing: null, modifier: null, first: command, rest: [] } } }] };
}

function parseShortRepeat(state: ParseState, context: ParserContext, redirects: boolean): NodeResult<CompoundCommandNode> {
  const keyword = currentToken(state);
  const count = readWordNode(skipTrivia(advanceState(state)));
  const result = parseCommand({ state: skipTrivia(count.state), context, readPostBodyRedirects: false });
  const post = redirects ? readPostCommandRedirects(result.state) : { state: result.state, redirects: [] };
  const tokens = tokenSlice(post.state, state.index, post.state.index);
  const headerRange = rangeFromTokens(tokens, keyword.range);
  const range = enclosingRange(headerRange, [result.node, ...post.redirects]);
  return { node: {
    kind: 'repeatCommand', range, raw: range.end.offset === headerRange.end.offset ? tokens.map((token) => token.value).join('') : textForRange(state.tokens, range),
    keyword: keyword.range, close: null, postBodyRedirects: post.redirects, count: count.node, body: listFromCommand(result.node),
  }, state: post.state };
}

function arithmeticSeparatorCount(text: string): number {
  let count = 0;
  let index = 0;
  while (index < text.length) {
    const char = text[index];
    if (char === '\\') { index += 2; continue; }
    if (char === '$' && (text[index + 1] === '(' || text[index + 1] === '{')) {
      const kind = text[index + 1] === '{' ? 'brace' : text[index + 2] === '(' ? 'arithmetic' : 'paren';
      index = delimitedEnd(text, index + 1, kind) ?? text.length;
    } else if (char === '(' || char === "'" || char === '"' || text.charCodeAt(index) === 96) {
      const kind = char === '(' ? 'patternParen' : char === "'" ? 'single' : char === '"' ? 'double' : 'backtick';
      index = delimitedEnd(text, index, kind) ?? text.length;
    } else { if (char === ';') count += 1; index += 1; }
  }
  return count;
}

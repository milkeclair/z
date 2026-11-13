import type { ListNode } from '../../ast';
import type { Token } from '../../lexer';
import type { NodeResult, ParseState } from '../state';

export type ListEnd = (token: Token) => boolean;

export type ParseList = (state: ParseState, isEnd: ListEnd) => NodeResult<ListNode>;

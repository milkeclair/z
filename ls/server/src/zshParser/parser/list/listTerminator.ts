import type { ListTerminatorType } from '../../ast';
import type { Token } from '../../lexer';

export function listTerminatorType(token: Token): ListTerminatorType | null {
  if (token.kind === 'newline') {
    return 'newline';
  } else if (token.operatorKind === 'semicolon') {
    return 'semicolon';
  } else if (token.operatorKind === 'background') {
    return 'background';
  } else if (token.operatorKind === 'backgroundPipe') {
    return 'backgroundPipe';
  } else if (token.operatorKind === 'backgroundBang') {
    return 'backgroundBang';
  } else {
    return null;
  }
}

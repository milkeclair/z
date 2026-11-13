import type { LogicalOperatorNode } from '../../../../ast';
import type { Token } from '../../../../lexer';

export function createLogicalOperatorNode(
  token: Token,
  type: LogicalOperatorNode['type'],
): LogicalOperatorNode {
  return {
    kind: 'logicalOperator',
    range: token.range,
    type,
  };
}

export function logicalOperatorType(token: Token): LogicalOperatorNode['type'] | null {
  const type = token.operatorKind;

  if (type === 'andIf' || type === 'orIf') {
    return type;
  } else {
    return null;
  }
}

import type { PipelineOperatorNode } from '../../../../../ast';
import type { Token } from '../../../../../lexer';

export function createPipelineOperatorNode(
  token: Token,
  type: PipelineOperatorNode['type'],
): PipelineOperatorNode {
  return {
    kind: 'pipelineOperator',
    range: token.range,
    type,
  };
}

export function pipelineOperatorType(token: Token): PipelineOperatorNode['type'] | null {
  const type = token.operatorKind;

  if (type === 'pipe' || type === 'pipeErr') {
    return type;
  } else {
    return null;
  }
}

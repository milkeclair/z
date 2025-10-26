export function isCommentLine(trimmedLine: string): boolean {
  return trimmedLine.startsWith('#');
}

export function hasIgnoreComment(trimmedLine: string): boolean {
  return trimmedLine.includes('# zls: ignore');
}

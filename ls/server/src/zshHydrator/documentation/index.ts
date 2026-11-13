import type { CommentNode, DocBlockNode } from '../../zshParser/ast';
import type { SourceRange } from '../../zshParser/lexer';
import type { HydrationOptions } from '../directive';
import { commentPayload, parseDirective } from '../directive';
import { parseParameter } from './parameter';
import type { DocDescription, DocExample, DocReply, DocReturn, FunctionDocumentation, HydrationDiagnostic, ParameterDoc } from './types';
export type * from './types';

type Section = { readonly kind: 'reply' | 'returns' | 'example'; readonly indent: number; readonly comments: CommentNode[]; readonly text: string[] };

export function parseFunctionDocumentation(block: DocBlockNode, source: string, options: HydrationOptions = {}): {
  readonly documentation: FunctionDocumentation; readonly exampleComments: ReadonlySet<number>;
} {
  const description: DocDescription[] = [];
  const parameters: ParameterDoc[] = [];
  const examples: DocExample[] = [];
  const diagnostics: HydrationDiagnostic[] = [];
  const exampleComments = new Set<number>();
  let reply: DocReply | null = null;
  let returns: DocReturn | null = null;
  let section: Section | null = null;
  const finish = (): void => {
    if (!section) return;
    const first = section.comments[0]; const last = section.comments[section.comments.length - 1];
    const range: SourceRange = { start: first.range.start, end: last.range.end };
    const raw = source.slice(range.start.offset, range.end.offset);
    const lines = [...section.text];
    while (lines.length > 0 && lines[0].trim() === '') lines.shift();
    while (lines.length > 0 && lines[lines.length - 1].trim() === '') lines.pop();
    const text = section.kind === 'example' ? lines.join('\n') : lines.join('\n').trim();
    if (section.kind === 'reply') reply = { kind: 'docReply', range, raw, text };
    else if (section.kind === 'returns') returns = { kind: 'docReturn', range, raw, text };
    else examples.push({ kind: 'docExample', range, raw, text });
    section = null;
  };
  for (const comment of block.comments) {
    const payloadInfo = commentPayload(comment);
    const payload = payloadInfo.text;
    const header = payload.startsWith('REPLY:') ? { kind: 'reply', length: 6 }
      : payload.startsWith('return:') ? { kind: 'returns', length: 7 }
        : payload.startsWith('example:') ? { kind: 'example', length: 8 } : null;
    if (header && !(section?.kind === 'example' && payloadInfo.start > section.indent)) {
      finish();
      const kind = header.kind === 'reply' ? 'reply' : header.kind === 'returns' ? 'returns' : 'example';
      section = { kind, indent: payloadInfo.start, comments: [comment], text: [payload.slice(header.length).trimStart()] };
      if (kind === 'example') exampleComments.add(comment.range.start.offset);
      continue;
    }
    if (section?.kind === 'example') {
      section.comments.push(comment);
      section.text.push(comment.text.slice(comment.text.startsWith('# ') ? 2 : comment.text.startsWith('#') ? 1 : 0));
      exampleComments.add(comment.range.start.offset);
      continue;
    }
    if (parseDirective(comment, options)) continue;
    if (payload.startsWith('$')) {
      finish();
      const parameter = parseParameter(comment);
      if (parameter) parameters.push(parameter);
      else diagnostics.push({ kind: 'invalidParameterDoc', range: comment.range, message: 'Expected $parameter[?]: description' });
    } else if (section) {
      section.comments.push(comment); section.text.push(payload);
    } else description.push({ kind: 'docDescription', range: comment.range, raw: comment.text, text: payload });
  }
  finish();
  return {
    documentation: { kind: 'functionDocumentation', range: block.range,
      raw: source.slice(block.range.start.offset, block.range.end.offset),
      description, parameters, reply, returns, examples, diagnostics },
    exampleComments,
  };
}

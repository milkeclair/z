import { List, OrderedSet } from 'immutable';
import type { CommentNode, DocBlockNode } from '../../zshParser/ast';
import type { HydrationOptions } from '../directive';
import { commentPayload, parseDirective } from '../directive';
import { parseParameter } from './parameter';
import type {
  DocDescription,
  DocExample,
  DocReply,
  DocReturn,
  FunctionDocumentation,
  HydrationDiagnostic,
  ParameterDoc,
} from './types';
export type * from './types';

type SectionKind = 'reply' | 'returns' | 'example';
type Section = {
  readonly kind: SectionKind;
  readonly indent: number;
  readonly first: CommentNode;
  readonly last: CommentNode;
  readonly text: List<string>;
};
type DocumentationProgress = {
  readonly description: List<DocDescription>;
  readonly parameters: List<ParameterDoc>;
  readonly examples: List<DocExample>;
  readonly diagnostics: List<HydrationDiagnostic>;
  readonly exampleComments: OrderedSet<number>;
  readonly reply: DocReply | null;
  readonly returns: DocReturn | null;
  readonly section: Section | null;
};
type SectionHeader = { readonly kind: SectionKind; readonly length: number };

function sectionHeader(payload: string): SectionHeader | null {
  if (payload.startsWith('REPLY:')) {
    return { kind: 'reply', length: 6 };
  }
  if (payload.startsWith('return:')) {
    return { kind: 'returns', length: 7 };
  }
  return payload.startsWith('example:') ? { kind: 'example', length: 8 } : null;
}

function finishSection(state: DocumentationProgress, source: string): DocumentationProgress {
  const section = state.section;
  if (!section) {
    return state;
  }
  const range = { start: section.first.range.start, end: section.last.range.end };
  const raw = source.slice(range.start.offset, range.end.offset);
  const lines = section.text
    .skipWhile((line) => line.trim() === '')
    .reverse()
    .skipWhile((line) => line.trim() === '')
    .reverse();
  const joined = lines.join('\n');
  const text = section.kind === 'example' ? joined : joined.trim();
  const base = { ...state, section: null };
  switch (section.kind) {
    case 'reply':
      return { ...base, reply: { kind: 'docReply', range, raw, text } };
    case 'returns':
      return { ...base, returns: { kind: 'docReturn', range, raw, text } };
    case 'example':
      return { ...base, examples: state.examples.push({ kind: 'docExample', range, raw, text }) };
  }
}

function readComment(
  state: DocumentationProgress,
  comment: CommentNode,
  source: string,
  options: HydrationOptions,
): DocumentationProgress {
  const info = commentPayload(comment),
    payload = info.text;
  const header = sectionHeader(payload);
  if (header && !(state.section?.kind === 'example' && info.start > state.section.indent)) {
    const finished = finishSection(state, source);
    return {
      ...finished,
      section: {
        kind: header.kind,
        indent: info.start,
        first: comment,
        last: comment,
        text: List([payload.slice(header.length).trimStart()]),
      },
      exampleComments:
        header.kind === 'example'
          ? finished.exampleComments.add(comment.range.start.offset)
          : finished.exampleComments,
    };
  }
  const section = state.section;
  if (section?.kind === 'example') {
    const content = comment.text.slice(
      comment.text.startsWith('# ') ? 2 : comment.text.startsWith('#') ? 1 : 0,
    );
    return {
      ...state,
      section: { ...section, last: comment, text: section.text.push(content) },
      exampleComments: state.exampleComments.add(comment.range.start.offset),
    };
  }
  if (parseDirective(comment, options)) {
    return state;
  }
  if (payload.startsWith('$')) {
    const finished = finishSection(state, source),
      parameter = parseParameter(comment);
    return parameter
      ? { ...finished, parameters: finished.parameters.push(parameter) }
      : {
          ...finished,
          diagnostics: finished.diagnostics.push({
            kind: 'invalidParameterDoc',
            range: comment.range,
            message: 'Expected $parameter[?]: description, optionally with [code] before the colon',
          }),
        };
  }
  if (section) {
    return { ...state, section: { ...section, last: comment, text: section.text.push(payload) } };
  }
  return {
    ...state,
    description: state.description.push({
      kind: 'docDescription',
      range: comment.range,
      raw: comment.text,
      text: payload,
    }),
  };
}

export function parseFunctionDocumentation(
  block: DocBlockNode,
  source: string,
  options: HydrationOptions = {},
): {
  readonly documentation: FunctionDocumentation;
  readonly exampleComments: ReadonlySet<number>;
} {
  const initial: DocumentationProgress = {
    description: List(),
    parameters: List(),
    examples: List(),
    diagnostics: List(),
    exampleComments: OrderedSet(),
    reply: null,
    returns: null,
    section: null,
  };
  const parsed = block.comments.reduce(
    (state, comment) => readComment(state, comment, source, options),
    initial,
  );
  const result = finishSection(parsed, source);
  return {
    documentation: {
      kind: 'functionDocumentation',
      range: block.range,
      raw: source.slice(block.range.start.offset, block.range.end.offset),
      description: result.description.toArray(),
      parameters: result.parameters.toArray(),
      reply: result.reply,
      returns: result.returns,
      examples: result.examples.toArray(),
      diagnostics: result.diagnostics.toArray(),
    },
    exampleComments: new Set(result.exampleComments),
  };
}

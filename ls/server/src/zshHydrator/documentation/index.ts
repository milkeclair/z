import { addValue, appendItems, collectArray, makeSet, skipWhile } from '../../util/collections';
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
  readonly text: ReadonlyArray<string>;
};

type DocumentationProgress = {
  readonly description: ReadonlyArray<DocDescription>;
  readonly parameters: ReadonlyArray<ParameterDoc>;
  readonly examples: ReadonlyArray<DocExample>;
  readonly diagnostics: ReadonlyArray<HydrationDiagnostic>;
  readonly exampleComments: ReadonlySet<number>;
  readonly reply: DocReply | null;
  readonly returns: DocReturn | null;
  readonly section: Section | null;
};

type SectionHeader = {
  readonly kind: SectionKind;
  readonly length: number;
};

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
  const lines = skipWhile(
    skipWhile(section.text, (line) => line.trim() === '').toReversed(),
    (line) => line.trim() === '',
  ).toReversed();
  const joined = lines.join('\n');
  const text = section.kind === 'example' ? joined : joined.trim();
  const base = { ...state, section: null };

  switch (section.kind) {
    case 'reply':
      return { ...base, reply: { kind: 'docReply', range, raw, text } };
    case 'returns':
      return { ...base, returns: { kind: 'docReturn', range, raw, text } };
    case 'example':
      return {
        ...base,
        examples: appendItems(state.examples, { kind: 'docExample', range, raw, text }),
      };
  }
}

function readComment(
  state: DocumentationProgress,
  comment: CommentNode,
  source: string,
  options: HydrationOptions,
): DocumentationProgress {
  const info = commentPayload(comment);
  const payload = info.text;
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
        text: collectArray([payload.slice(header.length).trimStart()]),
      },
      exampleComments:
        header.kind === 'example'
          ? addValue(finished.exampleComments, comment.range.start.offset)
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
      section: { ...section, last: comment, text: appendItems(section.text, content) },
      exampleComments: addValue(state.exampleComments, comment.range.start.offset),
    };
  }

  if (parseDirective(comment, options)) {
    return state;
  }

  if (payload.startsWith('$')) {
    const finished = finishSection(state, source);
    const parameter = parseParameter(comment);

    return parameter
      ? { ...finished, parameters: appendItems(finished.parameters, parameter) }
      : {
          ...finished,
          diagnostics: appendItems(finished.diagnostics, {
            kind: 'invalidParameterDoc',
            range: comment.range,
            message: 'Expected $parameter[?]: description, optionally with [code] before the colon',
          }),
        };
  }

  if (section) {
    return {
      ...state,
      section: { ...section, last: comment, text: appendItems(section.text, payload) },
    };
  }

  return {
    ...state,
    description: appendItems(state.description, {
      kind: 'docDescription',
      range: comment.range,
      raw: comment.text,
      text: payload,
    }),
  };
}

export function parseFunctionDocumentation(
  block: Pick<DocBlockNode, 'comments' | 'range'>,
  source: string,
  options: HydrationOptions = {},
): {
  readonly documentation: FunctionDocumentation;
  readonly exampleComments: ReadonlySet<number>;
} {
  const initial: DocumentationProgress = {
    description: collectArray(),
    parameters: collectArray(),
    examples: collectArray(),
    diagnostics: collectArray(),
    exampleComments: makeSet(),
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
      description: result.description,
      parameters: result.parameters,
      reply: result.reply,
      returns: result.returns,
      examples: result.examples,
      diagnostics: result.diagnostics,
    },
    exampleComments: new Set(result.exampleComments),
  };
}

import { appendItems, collectArray } from '../util/collections';
import { sectionExtractRegexes, sectionRegexes } from './regex';
import type { Result, Section } from './type';

type DocumentationState = {
  readonly section: Section;
  readonly description: ReadonlyArray<string>;
  readonly example: ReadonlyArray<string>;
  readonly result: Result;
};

function readLine(state: DocumentationState, line: string): DocumentationState {
  const text = line.trim();

  if (text === '') {
    return state;
  }

  if (sectionRegexes.parameters.test(text)) {
    const match = text.match(sectionExtractRegexes.parameters) || ['', ''];

    return {
      ...state,
      section: 'parameters',
      result: {
        ...state.result,
        parameters: [...state.result.parameters, { name: match[1], description: match[2] }],
      },
    };
  }

  if (sectionRegexes.reply.test(text)) {
    const match = text.match(sectionExtractRegexes.reply) || [''];

    return { ...state, section: 'reply', result: { ...state.result, reply: match[1] } };
  }

  if (sectionRegexes.return.test(text)) {
    const match = text.match(sectionExtractRegexes.return) || [''];

    return { ...state, section: 'return', result: { ...state.result, return: match[1] } };
  }

  if (sectionRegexes.example.test(text)) {
    return { ...state, section: 'example' };
  }

  if (state.section === 'example') {
    const match = text.match(sectionExtractRegexes.example) || [''];

    return { ...state, example: appendItems(state.example, match[1]) };
  }

  if (state.section === 'description') {
    const match = text.match(sectionExtractRegexes.description) || [''];

    return { ...state, description: appendItems(state.description, match[1]) };
  }

  return state;
}

export function Document(commentText: string): Result {
  const initial: DocumentationState = {
    section: 'description',
    description: collectArray(),
    example: collectArray(),
    result: { description: '', parameters: [], reply: '', return: '', example: '' },
  };
  const parsed = commentText.split('\n').reduce(readLine, initial);

  return {
    ...parsed.result,
    description: parsed.description.join('\n'),
    example: parsed.example.join('\n'),
  };
}

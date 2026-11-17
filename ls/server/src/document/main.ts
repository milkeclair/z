import { List } from 'immutable';
import { sectionExtractRegexes, sectionRegexes } from './regex';
import type { Result, Section } from './type';

type DocumentationState = {
  readonly section: Section;
  readonly description: List<string>;
  readonly example: List<string>;
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
    return { ...state, example: state.example.push(match[1]) };
  }
  if (state.section === 'description') {
    const match = text.match(sectionExtractRegexes.description) || [''];
    return { ...state, description: state.description.push(match[1]) };
  }
  return state;
}

export function Document(commentText: string): Result {
  const initial: DocumentationState = {
    section: 'description',
    description: List(),
    example: List(),
    result: { description: '', parameters: [], reply: '', return: '', example: '' },
  };
  const parsed = commentText.split('\n').reduce(readLine, initial);
  return {
    ...parsed.result,
    description: parsed.description.join('\n'),
    example: parsed.example.join('\n'),
  };
}

import { Result } from './type';
import { useCurrentSection } from './useCurrentSection';
import { sectionRegexes, sectionExtractRegexes } from './regex';

export function Document(commentText: string): Result {
  const lines = commentText.split('\n');
  const descriptionLines: string[] = [];
  const exampleLines: string[] = [];
  const result: Result = {
    description: '',
    parameters: [],
    reply: '',
    return: '',
    example: '',
  };

  const [currentSection, setCurrentSection] = useCurrentSection('description');

  const handleParameters = (trimmedLine: string) => {
    const isParam = sectionRegexes.parameters.test(trimmedLine);

    if (isParam) {
      const match = trimmedLine.match(sectionExtractRegexes.parameters) || ['', ''];

      result.parameters.push({ name: match[1], description: match[2] });
      setCurrentSection('parameters');
    }
  };

  const handleReply = (trimmedLine: string) => {
    const isReply = sectionRegexes.reply.test(trimmedLine);

    if (isReply) {
      const match = trimmedLine.match(sectionExtractRegexes.reply) || [''];

      result.reply = match[1];
      setCurrentSection('reply');
    }
  };

  const handleReturn = (trimmedLine: string) => {
    const isReturn = sectionRegexes.return.test(trimmedLine);

    if (isReturn) {
      const match = trimmedLine.match(sectionExtractRegexes.return) || [''];

      result.return = match[1];
      setCurrentSection('return');
    }
  };

  const handleExample = (trimmedLine: string) => {
    const isExample = sectionRegexes.example.test(trimmedLine);

    if (isExample) {
      const match = trimmedLine.match(sectionExtractRegexes.example) || [''];

      exampleLines.push(match[1]);
      setCurrentSection('example');
    } else if (currentSection() === 'example') {
      const match = trimmedLine.match(sectionExtractRegexes.example) || [''];

      exampleLines.push(match[1]);
    }
  };

  const handleDescription = (trimmedLine: string) => {
    if (currentSection() === 'description') {
      const match = trimmedLine.match(sectionExtractRegexes.description) || [''];

      descriptionLines.push(match[1]);
    }
  };

  for (const line of lines) {
    const trimmedLine = line.trim();
    if (trimmedLine === '') continue;

    handleParameters(trimmedLine);
    handleReply(trimmedLine);
    handleReturn(trimmedLine);
    handleExample(trimmedLine);
    handleDescription(trimmedLine);
  }

  result.description = descriptionLines.join('\n');
  result.example = exampleLines.join('\n');

  return result;
}

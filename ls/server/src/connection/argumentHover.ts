import path from 'path';
import { fileURLToPath } from 'url';
import { HoverParams, MarkupKind, TextDocument, TextDocuments } from '../vscode_type';
import { Func, FuncArg } from '../getFunctions/type';
import { findFunctionEnd } from '../diagnostics/unusedArgument/function';
import { activeParameter, findCallContext } from './callContext';
import { argumentMarkdown, functionDocument } from "./functionDoc";

type LocalArgument = {
  func: Func;
  arg: FuncArg;
};

type TokenRange = {
  start: number;
  end: number;
};

function shellTokenAt(line: string, character: number): TokenRange | null {
  let tokenStart = 0;
  let inQuote = false;
  let quoteChar = '';

  for (let i = 0; i <= line.length; i++) {
    const char = line[i] ?? '';
    const atEnd = i === line.length;

    if (!atEnd && (char === '"' || char === "'") && (i === 0 || line[i - 1] !== '\\')) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = char;
      } else if (quoteChar === char) {
        inQuote = false;
        quoteChar = '';
      }
    }

    const isDelimiter = atEnd || (!inQuote && /\s/.test(char));
    if (!isDelimiter) continue;

    if (character >= tokenStart && character <= i && i > tokenStart) {
      return {
        start: tokenStart,
        end: i,
      };
    }

    tokenStart = i + 1;
  }

  return null;
}

function sameFileFunctions(params: HoverParams, functions: Func[], projectRoot: string): Func[] {
  const absolutePath = path.resolve(fileURLToPath(params.textDocument.uri));
  const relativePath = path.relative(projectRoot, absolutePath);

  return functions.filter((func) => func.file === relativePath);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function argByName(func: Func, name: string): FuncArg | null {
  if (name === '@') {
    return func.args.find((arg) => !arg.isNamed && arg.name === '@') ?? null;
  }

  const position = Number.parseInt(name, 10);
  if (!Number.isNaN(position)) {
    return func.args.find((arg) => !arg.isNamed && arg.position === position) ?? null;
  }

  return func.args.find((arg) => arg.isNamed && arg.name === name) ?? null;
}

function argFromLocalAssignment(line: string, word: string, func: Func): FuncArg | null {
  const localPattern = new RegExp(`(?:^|&&\\s*)local\\s+${escapeRegExp(word)}=([^\\s]+)`);
  const localMatch = line.match(localPattern);
  if (!localMatch) return null;

  const value = localMatch[1];
  const directArgMatch = value.match(/^\$\{?(\d+|@)\}?$/);
  if (directArgMatch) return argByName(func, directArgMatch[1]);

  const namedFromHashMatch = value.match(/^\$[a-zA-Z_][a-zA-Z0-9_]*\[([a-zA-Z_][a-zA-Z0-9_]*)\]$/);
  if (namedFromHashMatch) return argByName(func, namedFromHashMatch[1]);

  const namedReplyMatch = line.match(/\bz\.arg\.named\s+([a-zA-Z_][a-zA-Z0-9_]*)\b/);
  if (value === '$REPLY' && namedReplyMatch) {
    return argByName(func, namedReplyMatch[1]);
  }

  return null;
}

function localArgument(
  lines: string[],
  funcs: Func[],
  lineIndex: number,
  word: string,
): LocalArgument | null {
  for (const func of funcs) {
    const startLine = func.line - 1;
    const endLine = findFunctionEnd(lines, startLine);
    if (lineIndex < startLine || lineIndex > endLine) continue;

    for (let i = startLine + 1; i <= lineIndex; i++) {
      const arg = argFromLocalAssignment(lines[i], word, func);
      if (arg) return { func, arg };
    }
  }

  return null;
}

function argumentFromCall(
  document: TextDocument,
  params: HoverParams,
  functions: Func[],
): LocalArgument | null {
  const line = document.getText({
    start: { line: params.position.line, character: 0 },
    end: { line: params.position.line, character: Number.MAX_SAFE_INTEGER },
  });
  const token = shellTokenAt(line, params.position.character);
  if (!token) return null;

  const context = findCallContext(line.substring(0, token.end), functions);
  if (!context) return null;

  const arg = activeParameter(context.func, context.argsText);
  if (!arg) return null;

  return { func: context.func, arg };
}

function argumentHoverMarkdown(projectRoot: string, localArg: LocalArgument): string {
  const doc = functionDocument(projectRoot, localArg.func);
  return argumentMarkdown(projectRoot, localArg.func, localArg.arg, doc);
}

export function zArgumentHover({
  params,
  documents,
  functions,
  projectRoot,
  word,
}: {
  params: HoverParams;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
  projectRoot: string;
  word: string;
}) {
  if (word === '') return null;

  const document = documents.get(params.textDocument.uri);
  if (!document) return null;

  const callArg = argumentFromCall(document, params, functions);
  if (callArg) {
    return {
      contents: {
        kind: MarkupKind.Markdown,
        value: argumentHoverMarkdown(projectRoot, callArg),
      },
    };
  }

  const lines = document.getText().split('\n');
  const localArg = localArgument(
    lines,
    sameFileFunctions(params, functions, projectRoot),
    params.position.line,
    word,
  );
  if (!localArg) return null;

  return {
    contents: {
      kind: MarkupKind.Markdown,
      value: argumentHoverMarkdown(projectRoot, localArg),
    },
  };
}

import type { CodeProgram } from '../embeddedCode';
import {
  MarkupKind, ParameterInformation, SignatureHelp, SignatureHelpParams,
  SignatureInformation, TextDocument, TextDocuments,
} from '../vscode_type';
import type { Result } from '../document/type';
import type { FuncArg } from '../getFunctions/type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { FunctionTarget } from '../refreshFunctions/target';
import { cursorAt } from './ast/cursor';
import { calledFunction, activeArgument } from './ast/context';
import { argumentDescription, argumentDisplay, markdownDocumentation } from './functionDoc';

function signatureToken(arg: FuncArg): string {
  const token = argumentDisplay(arg);
  return arg.optional ? '[' + token + ']' : token;
}

function parameterInformation(doc: Result, arg: FuncArg): ParameterInformation {
  return { label: argumentDisplay(arg), documentation: markdownDocumentation(argumentDescription(doc, arg)) };
}

function signatureInformation(target: FunctionTarget, index: number): SignatureInformation {
  const func = target.info;
  return {
    label: [func.name, ...func.args.map(signatureToken)].join(' '),
    documentation: { kind: MarkupKind.Markdown, value: func.documentation.description },
    parameters: func.args.map(arg => parameterInformation(func.documentation, arg)),
    activeParameter: index,
  };
}

export function zSignatureHelp({ params, documents, snapshot, programs }: {
  params: SignatureHelpParams; documents: Pick<TextDocuments<TextDocument>, 'get'>; snapshot: FunctionSnapshot; programs?: readonly CodeProgram[];
}): SignatureHelp | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;
  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position), programs);
  if (!cursor) return null;
  const target = calledFunction(snapshot, cursor);
  const active = target && activeArgument(target, cursor);
  return target && active ? {
    signatures: [signatureInformation(target, active.index)], activeSignature: 0, activeParameter: active.index,
  } : null;
}

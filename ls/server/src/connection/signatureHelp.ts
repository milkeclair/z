import type { Result } from '../document/type';
import type { FuncArg } from '../getFunctions/type';
import type { FunctionTarget } from '../refreshFunctions/target';
import {
  MarkupKind,
  ParameterInformation,
  SignatureHelp,
  SignatureHelpParams,
  SignatureInformation,
} from '../vscode_type';
import { activeArgument, calledFunction } from './ast/context';
import { cursorAt } from './ast/cursor';
import { argumentDescription, argumentDisplay, markdownDocumentation } from './functionDoc';
import type { LanguageFeatureRequest } from './type';

function signatureToken(arg: FuncArg): string {
  const token = argumentDisplay(arg);
  return arg.optional ? '[' + token + ']' : token;
}

function parameterInformation(doc: Result, arg: FuncArg): ParameterInformation {
  return {
    label: argumentDisplay(arg),
    documentation: markdownDocumentation(argumentDescription(doc, arg)),
  };
}

function signatureInformation(target: FunctionTarget, index: number): SignatureInformation {
  const func = target.info;
  return {
    label: [func.name, ...func.args.map(signatureToken)].join(' '),
    documentation: { kind: MarkupKind.Markdown, value: func.documentation.description },
    parameters: func.args.map((arg) => parameterInformation(func.documentation, arg)),
    activeParameter: index,
  };
}

export function zSignatureHelp({
  params,
  documents,
  snapshot,
  programs,
}: LanguageFeatureRequest<SignatureHelpParams>): SignatureHelp | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) {
    return null;
  }
  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position), programs);
  if (!cursor) {
    return null;
  }
  const target = calledFunction(snapshot, cursor);
  const active = target && activeArgument(target, cursor);
  return target && active
    ? {
        signatures: [signatureInformation(target, active.index)],
        activeSignature: 0,
        activeParameter: active.index,
      }
    : null;
}

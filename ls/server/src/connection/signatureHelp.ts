import {
  MarkupKind,
  ParameterInformation,
  SignatureHelp,
  SignatureHelpParams,
  SignatureInformation,
  TextDocument,
  TextDocuments,
} from "../vscode_type";
import { Result } from "../document/type";
import { Func, FuncArg } from "../getFunctions/type";
import { activeParameterIndex, findCallContext } from "./callContext";
import {
  argumentDescription,
  argumentToken,
  functionDocument,
  markdownDocumentation,
} from "./functionDoc";

function signatureToken(arg: FuncArg): string {
  const token = argumentToken(arg);
  if (!arg.optional) return token;

  return `[${token}]`;
}

function parameterInformation(doc: Result | null, arg: FuncArg): ParameterInformation {
  const description = argumentDescription(doc, arg);

  return {
    label: argumentToken(arg),
    documentation: markdownDocumentation(description),
  };
}

function signatureInformation(projectRoot: string, func: Func): SignatureInformation {
  const doc = functionDocument(projectRoot, func);
  const description = doc?.description ?? "";

  return {
    label: [func.name, ...func.args.map(signatureToken)].join(" "),
    documentation: {
      kind: MarkupKind.Markdown,
      value: description,
    },
    parameters: func.args.map((arg) => parameterInformation(doc, arg)),
  };
}

export function zSignatureHelp({
  params,
  documents,
  functions,
  projectRoot,
}: {
  params: SignatureHelpParams;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
  projectRoot: string;
}): SignatureHelp | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;

  const lineBeforeCursor = document.getText({
    start: { line: params.position.line, character: 0 },
    end: params.position,
  });
  const context = findCallContext(lineBeforeCursor, functions);
  if (!context) return null;
  if (context.func.args.length === 0) return null;

  const activeParameter = activeParameterIndex(context.func, context.argsText);
  if (activeParameter === null) return null;

  return {
    signatures: [signatureInformation(projectRoot, context.func)],
    activeSignature: 0,
    activeParameter,
  };
}

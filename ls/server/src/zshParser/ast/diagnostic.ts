export type ParserDiagnosticKind =
  | 'nestingLimitExceeded'
  | 'unexpectedToken'
  | 'missingTerminator'
  | 'missingFunctionBody'
  | 'missingClosingBrace'
  | 'missingClosingParen'
  | 'missingConditionEnd'
  | 'missingArithmeticEnd'
  | 'missingCompoundEnd'
  | 'unknownCommand';

import type {
  FileNode,
  FunctionDefinitionNode,
  SimpleCommandNode,
  WordNode,
} from '../../zshParser/ast';
import type { SourceRange } from '../../zshParser/lexer';

export type ClassDefinitionScopeLocation =
  | { readonly kind: 'file' }
  | {
      readonly kind: 'function';
      readonly offset: number;
    };

export type ClassScopeLocation =
  | ClassDefinitionScopeLocation
  | {
      readonly kind: 'classMethod';
      readonly offset: number;
    };

export type ClassMethodAccess = 'read' | 'write';

export type ClassMethodBody =
  | {
      readonly kind: 'inline';
      readonly range: SourceRange;
    }
  | {
      readonly kind: 'block';
      readonly range: SourceRange;
      readonly end: SourceRange | null;
    };

export type ClassInformation =
  | {
      readonly kind: 'classDefinition';
      readonly name: string;
      readonly scope: ClassDefinitionScopeLocation;
      readonly state: 'published' | 'aborted' | 'incomplete';
      readonly range: SourceRange;
    }
  | {
      readonly kind: 'classAttribute';
      readonly name: string;
      readonly classOffset: number;
    }
  | {
      readonly kind: 'classMethod';
      readonly name: string;
      readonly classOffset: number;
      readonly access: ClassMethodAccess;
      readonly body: ClassMethodBody;
    }
  | {
      readonly kind: 'classInstance';
      readonly name: string;
      readonly className: string;
      readonly scope: ClassScopeLocation;
    };

export type HydratedClassCommand = SimpleCommandNode & {
  readonly hydration: ClassInformation;
};

export type ClassAttribute = {
  readonly kind: 'classAttribute';
  readonly name: string;
  readonly declaration: SimpleCommandNode;
  readonly nameNode: WordNode;
  readonly defaultValue: WordNode;
  readonly defaultValueRange: SourceRange;
};

export type ClassMethod = {
  readonly kind: 'classMethod';
  readonly name: string;
  readonly access: ClassMethodAccess;
  readonly declaration: SimpleCommandNode;
  readonly nameNode: WordNode;
  readonly body:
    | {
        readonly kind: 'inline';
        readonly value: WordNode;
      }
    | {
        readonly kind: 'block';
        readonly range: SourceRange;
        readonly end: SourceRange | null;
      };
};

export type ClassDefinition = {
  readonly kind: 'classDefinition';
  readonly name: string;
  readonly declaration: SimpleCommandNode;
  readonly file: FileNode;
  readonly nameNode: WordNode;
  readonly scope: FunctionDefinitionNode | null;
  readonly state: 'published' | 'aborted' | 'incomplete';
  readonly range: SourceRange;
  readonly attributes: readonly ClassAttribute[];
  readonly methods: readonly ClassMethod[];
};

export type ClassInstance = {
  readonly kind: 'classInstance';
  readonly name: string;
  readonly className: string;
  readonly declaration: SimpleCommandNode;
  readonly nameNode: WordNode;
  readonly classNameNode: WordNode;
  readonly file: FileNode;
  readonly scope:
    | { readonly kind: 'file' }
    | {
        readonly kind: 'function';
        readonly declaration: FunctionDefinitionNode;
      }
    | {
        readonly kind: 'classMethod';
        readonly declaration: SimpleCommandNode;
      };
};

export type ClassMethodScope = {
  readonly range: SourceRange;
  readonly method: ClassMethod;
};

export type ClassFileHydration = {
  readonly definitions: readonly ClassDefinition[];
  readonly instances: readonly ClassInstance[];
  readonly methodScopes: ReadonlyMap<FunctionDefinitionNode | null, readonly ClassMethodScope[]>;
};

export type { ControlComment, Directive, DirectiveArgument, HydrationOptions } from './directive';
export type * from './documentation';
export { createZshFileHydration } from './fileHydration';
export type { HydratedFunction, ZshFileHydration } from './fileHydration';
export {
  directivesOf,
  documentationOf,
  hydrateAst,
  isHydratedComment,
  isHydratedDocBlock,
} from './hydrate';
export type { HydratedComment, HydratedDocBlock } from './hydrate';
export {
  EmptyZshHydrator,
  createZshHydrator,
  functionsFromZshHydrator,
  refreshZshHydrator,
} from './hydrator';
export type { ZshHydrator } from './hydrator';
export {
  hydrateClasses,
  classesFromAst,
  classInformationOf,
  isHydratedClassCommand,
  classMethodAt,
} from './classes';
export type {
  ClassInformation,
  HydratedClassCommand,
  ClassFileHydration,
  ClassDefinition,
  ClassMethod,
  ClassAttribute,
  ClassInstance,
} from './classes';

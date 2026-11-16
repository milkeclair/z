import type { ZshFileHydration } from '../zshHydrator';
import { directivesOf } from '../zshHydrator';

export type IgnoreControls = ReadonlyMap<number, ReadonlySet<string>>;

/** Collect controls from hydrated comments; prose and example text do not suppress diagnostics. */
export function collectIgnoreControls(file: ZshFileHydration): IgnoreControls {
  const ignores = new Map<number, ReadonlySet<string>>();
  for (const comment of file.ast.comments) {
    for (const directive of directivesOf(comment)) {
      if (directive.namespace === 'zls' && directive.command === 'ignore') {
        ignores.set(comment.range.start.line, new Set(directive.arguments.map(argument => argument.value)));
      }
    }
  }
  return ignores;
}

/** Match whole-line suppression or an explicitly selected diagnostic code. */
export function ignored(controls: IgnoreControls, line: number, code?: string): boolean {
  const codes = controls.get(line);
  return codes !== undefined && (codes.size === 0 || code !== undefined && codes.has(code));
}

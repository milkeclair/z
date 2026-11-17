import type { ZshFileHydration } from '../zshHydrator';
import { directivesOf } from '../zshHydrator';

export type IgnoreControls = ReadonlyMap<number, ReadonlySet<string>>;

/** 付加済みコメントから制御情報を集める。説明文や例示内の文字列では診断を抑制しない。 */
export function collectIgnoreControls(file: ZshFileHydration): IgnoreControls {
  const ignores = new Map<number, ReadonlySet<string>>();
  for (const comment of file.ast.comments) {
    for (const directive of directivesOf(comment)) {
      if (directive.namespace === 'zls' && directive.command === 'ignore') {
        ignores.set(
          comment.range.start.line,
          new Set(directive.arguments.map((argument) => argument.value)),
        );
      }
    }
  }
  return ignores;
}

/** 行全体の抑制、または指定された診断コードの抑制に一致するか判定する。 */
export function ignored(controls: IgnoreControls, line: number, code?: string): boolean {
  const codes = controls.get(line);
  return codes !== undefined && (codes.size === 0 || (code !== undefined && codes.has(code)));
}

import { spawn } from 'node:child_process';

export type ShellEnvironment =
  | { readonly kind: 'available'; readonly commands: ReadonlySet<string>; readonly builtins: ReadonlySet<string>;
      readonly aliases: ReadonlySet<string>; readonly globalAliases: ReadonlySet<string>;
      readonly suffixAliases: ReadonlySet<string>; readonly functions: ReadonlySet<string>; readonly commandBuiltins: boolean }
  | { readonly kind: 'unavailable'; readonly reason: 'not-started' | 'spawn' | 'timeout' | 'output-limit' | 'invalid-output' };

export function emptyShellEnvironment(): ShellEnvironment {
  return { kind: 'unavailable', reason: 'not-started' };
}

const QUERY = [
  'builtin zmodload zsh/parameter || exit 1',
  'builtin rehash',
  "builtin printf '__ZLS_ENV_V1__\\0'",
  "for zlsName in \"${(@k)commands}\"; do builtin printf \"command\\0%s\\0\" \"$zlsName\"; done",
  "for zlsName in \"${(@k)builtins}\"; do builtin printf \"builtin\\0%s\\0\" \"$zlsName\"; done",
  "for zlsName in \"${(@k)aliases}\"; do builtin printf \"alias\\0%s\\0\" \"$zlsName\"; done",
  "for zlsName in \"${(@k)galiases}\"; do builtin printf \"global-alias\\0%s\\0\" \"$zlsName\"; done",
  "for zlsName in \"${(@k)saliases}\"; do builtin printf \"suffix-alias\\0%s\\0\" \"$zlsName\"; done",
  "for zlsName in \"${(@k)functions}\"; do builtin printf \"function\\0%s\\0\" \"$zlsName\"; done",
  'if [[ -o POSIX_BUILTINS ]]; then builtin printf "option\\0command-builtins\\0"; fi',
  "builtin printf '__ZLS_ENV_END__\\0'",
].join('\n');

export function parseShellEnvironment(output: string): ShellEnvironment {
  const marker = '__ZLS_ENV_V1__' + String.fromCharCode(0);
  const start = output.indexOf(marker);
  if (start < 0) return { kind: 'unavailable', reason: 'invalid-output' };
  const words = output.slice(start + marker.length).split(String.fromCharCode(0));
  let commandBuiltins = false;
  const commands = new Set<string>();
  const builtins = new Set<string>();
  const aliases = new Set<string>();
  const functions = new Set<string>();
  const globalAliases = new Set<string>();
  const suffixAliases = new Set<string>();
  for (let index = 0; index < words.length; index += 2) {
    const kind = words[index];
    if (kind === '__ZLS_ENV_END__') return { kind: 'available', commands, builtins, aliases, globalAliases, suffixAliases, functions, commandBuiltins };
    const name = words[index + 1];
    if (!name) return { kind: 'unavailable', reason: 'invalid-output' };
    switch (kind) {
      case 'option':
        if (name !== 'command-builtins') return { kind: 'unavailable', reason: 'invalid-output' };
        commandBuiltins = true; break;
      case 'command': commands.add(name); break;
      case 'builtin': builtins.add(name); break;
      case 'alias': aliases.add(name); break;
      case 'global-alias': globalAliases.add(name); break;
      case 'suffix-alias': suffixAliases.add(name); break;
      case 'function': functions.add(name); break;
      default: return { kind: 'unavailable', reason: 'invalid-output' };
    }
  }
  return { kind: 'unavailable', reason: 'invalid-output' };
}

export function readShellEnvironment({
  env = process.env, timeout = 3000, maxBytes = 2 * 1024 * 1024,
}: { readonly env?: NodeJS.ProcessEnv; readonly timeout?: number; readonly maxBytes?: number } = {}): Promise<ShellEnvironment> {
  return new Promise(resolve => {
    const child = spawn('zsh', ['-ic', QUERY], {
      env, stdio: ['ignore', 'pipe', 'pipe'], detached: process.platform !== 'win32',
    });
    const output: Buffer[] = [];
    let bytes = 0;
    let settled = false;
    function stop(): void {
      if (!child.pid) return;
      try {
        if (process.platform === 'win32') child.kill('SIGKILL');
        else process.kill(-child.pid, 'SIGKILL');
      } catch {
        child.kill('SIGKILL');
      }
    }
    function finish(result: ShellEnvironment): void {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      stop();
      resolve(result);
    }
    function receive(buffer: Buffer, keep: boolean): void {
      bytes += buffer.length;
      if (bytes > maxBytes) finish({ kind: 'unavailable', reason: 'output-limit' });
      else if (keep && !settled) output.push(buffer);
    }
    const timer = setTimeout(() => finish({ kind: 'unavailable', reason: 'timeout' }), timeout);
    child.stdout.on('data', (buffer: Buffer) => receive(buffer, true));
    child.stderr.on('data', (buffer: Buffer) => receive(buffer, false));
    child.on('error', () => finish({ kind: 'unavailable', reason: 'spawn' }));
    child.on('close', code => finish(code === 0
      ? parseShellEnvironment(Buffer.concat(output).toString('utf8'))
      : { kind: 'unavailable', reason: 'invalid-output' }));
  });
}

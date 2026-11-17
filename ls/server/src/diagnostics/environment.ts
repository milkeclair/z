import { OrderedSet } from 'immutable';
import { spawn } from 'node:child_process';
import { createIOState } from '../util/ioState';
import { again, done, loop } from '../util/loop';

export type ShellEnvironment =
  | {
      readonly kind: 'available';
      readonly commands: ReadonlySet<string>;
      readonly builtins: ReadonlySet<string>;
      readonly aliases: ReadonlySet<string>;
      readonly globalAliases: ReadonlySet<string>;
      readonly suffixAliases: ReadonlySet<string>;
      readonly functions: ReadonlySet<string>;
      readonly commandBuiltins: boolean;
    }
  | {
      readonly kind: 'unavailable';
      readonly reason: 'not-started' | 'spawn' | 'timeout' | 'output-limit' | 'invalid-output';
    };

export function emptyShellEnvironment(): ShellEnvironment {
  return { kind: 'unavailable', reason: 'not-started' };
}

const QUERY = [
  'builtin zmodload zsh/parameter || exit 1',
  'builtin rehash',
  "builtin printf '__ZLS_ENV_V1__\\0'",
  'for zlsName in "${(@k)commands}"; do builtin printf "command\\0%s\\0" "$zlsName"; done',
  'for zlsName in "${(@k)builtins}"; do builtin printf "builtin\\0%s\\0" "$zlsName"; done',
  'for zlsName in "${(@k)aliases}"; do builtin printf "alias\\0%s\\0" "$zlsName"; done',
  'for zlsName in "${(@k)galiases}"; do builtin printf "global-alias\\0%s\\0" "$zlsName"; done',
  'for zlsName in "${(@k)saliases}"; do builtin printf "suffix-alias\\0%s\\0" "$zlsName"; done',
  'for zlsName in "${(@k)functions}"; do builtin printf "function\\0%s\\0" "$zlsName"; done',
  'if [[ -o POSIX_BUILTINS ]]; then builtin printf "option\\0command-builtins\\0"; fi',
  "builtin printf '__ZLS_ENV_END__\\0'",
].join('\n');

type SymbolTables = {
  readonly commands: OrderedSet<string>;
  readonly builtins: OrderedSet<string>;
  readonly aliases: OrderedSet<string>;
  readonly functions: OrderedSet<string>;
  readonly globalAliases: OrderedSet<string>;
  readonly suffixAliases: OrderedSet<string>;
};
type EnvironmentProgress = {
  readonly index: number;
  readonly commandBuiltins: boolean;
  readonly tables: SymbolTables;
};
const TABLE_NAMES: Readonly<Record<string, keyof SymbolTables | undefined>> = {
  command: 'commands',
  builtin: 'builtins',
  alias: 'aliases',
  function: 'functions',
  'global-alias': 'globalAliases',
  'suffix-alias': 'suffixAliases',
};

function environmentFrom(progress: EnvironmentProgress): ShellEnvironment {
  const tables = progress.tables;
  return {
    kind: 'available',
    commandBuiltins: progress.commandBuiltins,
    commands: new Set(tables.commands),
    builtins: new Set(tables.builtins),
    aliases: new Set(tables.aliases),
    functions: new Set(tables.functions),
    globalAliases: new Set(tables.globalAliases),
    suffixAliases: new Set(tables.suffixAliases),
  };
}

export function parseShellEnvironment(output: string): ShellEnvironment {
  const marker = '__ZLS_ENV_V1__' + String.fromCharCode(0);
  const start = output.indexOf(marker);
  if (start < 0) {
    return { kind: 'unavailable', reason: 'invalid-output' };
  }
  const words = output.slice(start + marker.length).split(String.fromCharCode(0));
  const initial: EnvironmentProgress = {
    index: 0,
    commandBuiltins: false,
    tables: {
      commands: OrderedSet(),
      builtins: OrderedSet(),
      aliases: OrderedSet(),
      functions: OrderedSet(),
      globalAliases: OrderedSet(),
      suffixAliases: OrderedSet(),
    },
  };
  return loop<EnvironmentProgress, ShellEnvironment>(initial, (progress) => {
    const kind = words[progress.index];
    if (kind === '__ZLS_ENV_END__') {
      return done(environmentFrom(progress));
    }
    const name = words[progress.index + 1];
    if (!name) {
      return done({ kind: 'unavailable', reason: 'invalid-output' });
    }
    if (kind === 'option') {
      return name === 'command-builtins'
        ? again({ ...progress, index: progress.index + 2, commandBuiltins: true })
        : done({ kind: 'unavailable', reason: 'invalid-output' });
    }
    const table = Object.hasOwn(TABLE_NAMES, kind) ? TABLE_NAMES[kind] : undefined;
    return table
      ? again({
          ...progress,
          index: progress.index + 2,
          tables: {
            ...progress.tables,
            [table]: progress.tables[table].add(name),
          },
        })
      : done({ kind: 'unavailable', reason: 'invalid-output' });
  });
}

type ProbeState = {
  readonly bytes: number;
  readonly settled: boolean;
  readonly output: readonly Buffer[];
};

export function readShellEnvironment({
  env = process.env,
  timeout = 3000,
  maxBytes = 2 * 1024 * 1024,
}: {
  readonly env?: NodeJS.ProcessEnv;
  readonly timeout?: number;
  readonly maxBytes?: number;
} = {}): Promise<ShellEnvironment> {
  return new Promise((resolve) => {
    const child = spawn('zsh', ['-ic', QUERY], {
      env,
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: process.platform !== 'win32',
    });
    const state = createIOState<ProbeState>({ bytes: 0, settled: false, output: [] });
    function stop(): void {
      if (!child.pid) {
        return;
      }
      try {
        if (process.platform === 'win32') {
          child.kill('SIGKILL');
        } else {
          process.kill(-child.pid, 'SIGKILL');
        }
      } catch {
        child.kill('SIGKILL');
      }
    }
    function finish(result: ShellEnvironment): void {
      if (state.read().settled) {
        return;
      }
      state.update((previous) => ({ ...previous, settled: true }));
      clearTimeout(timer);
      process.removeListener('exit', stop);
      stop();
      resolve(result);
    }
    function receive(buffer: Buffer, keep: boolean): void {
      state.update((previous) => ({ ...previous, bytes: previous.bytes + buffer.length }));
      const current = state.read();
      if (current.bytes > maxBytes) {
        finish({ kind: 'unavailable', reason: 'output-limit' });
      } else if (keep && !current.settled) {
        state.update((previous) => ({ ...previous, output: [...previous.output, buffer] }));
      }
    }
    process.once('exit', stop);
    const timer = setTimeout(() => finish({ kind: 'unavailable', reason: 'timeout' }), timeout);
    child.stdout.on('data', (buffer: Buffer) => receive(buffer, true));
    child.stderr.on('data', (buffer: Buffer) => receive(buffer, false));
    child.on('error', () => finish({ kind: 'unavailable', reason: 'spawn' }));
    child.on('close', (code) =>
      finish(
        code === 0
          ? parseShellEnvironment(Buffer.concat(state.read().output).toString('utf8'))
          : { kind: 'unavailable', reason: 'invalid-output' },
      ),
    );
  });
}

import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { readShellEnvironment, parseShellEnvironment } from '../../src/diagnostics/environment';

const roots: string[] = [];
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-lsp-env-'));
  roots.push(root);
  fs.mkdirSync(path.join(root, 'bin'));
  fs.mkdirSync(path.join(root, 'functions'));
  fs.writeFileSync(path.join(root, 'bin', 'fixture-command'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
  fs.writeFileSync(path.join(root, 'functions', 'fixture-autoload'), 'print loaded > ' + JSON.stringify(path.join(root, 'autoload-executed')) + '\n');
  const rc = [
    'path=(' + JSON.stringify(path.join(root, 'bin')) + ' $path)',
    'fpath=(' + JSON.stringify(path.join(root, 'functions')) + ' $fpath)',
    "alias fixture-alias='print alias'",
    'fixture-function() { : }',
    'autoload -Uz fixture-autoload',
  ].join('\n');
  fs.writeFileSync(path.join(root, '.zshrc'), rc);
  return { root, env: { ...process.env, ZDOTDIR: root } };
}
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
describe('shell environment', () => {
  test('実Zshの外部コマンド・builtin・alias・autoloadと関数を取得する', async () => {
    const f = fixture();
    const environment = await readShellEnvironment({ env: f.env });
    expect(environment.kind).toBe('available');
    if (environment.kind !== 'available') throw new Error(environment.reason);
    expect(environment.commands.has('fixture-command')).toBe(true);
    expect(environment.builtins.has('print')).toBe(true);
    expect(environment.aliases.has('fixture-alias')).toBe(true);
    expect(environment.functions.has('fixture-function')).toBe(true);
    expect(environment.functions.has('fixture-autoload')).toBe(true);
    expect(fs.existsSync(path.join(f.root, 'autoload-executed'))).toBe(false);
  });
  test('commandのbuiltin解決に関わる実Zshオプションも保持する', async () => {
    const f = fixture();
    fs.appendFileSync(path.join(f.root, '.zshrc'), '\nsetopt POSIX_BUILTINS\n');
    const result = await readShellEnvironment({ env: f.env });
    expect(result.kind === 'available' && result.commandBuiltins).toBe(true);
  });
  test('起動失敗は未解決のまま返す', async () => {
    const f = fixture();
    expect(await readShellEnvironment({ env: { ...f.env, PATH: path.join(f.root, 'bin') } }))
      .toEqual({ kind: 'unavailable', reason: 'spawn' });
  });
  test('時間制限で起動したprocess groupを終了する', async () => {
    const f = fixture();
    const pidFile = path.join(f.root, 'pids');
    fs.writeFileSync(path.join(f.root, '.zshrc'), 'sleep 10 &\nprint -r -- "$$ $!" > ' + JSON.stringify(pidFile) + '\nwait\n');
    const start = Date.now();
    expect(await readShellEnvironment({ env: f.env, timeout: 1500 })).toEqual({ kind: 'unavailable', reason: 'timeout' });
    expect(Date.now() - start).toBeLessThan(4000);
    const pids = fs.readFileSync(pidFile, 'utf8').trim().split(' ');
    await expect.poll(() => pids.every(pid => {
      try { return fs.readFileSync('/proc/' + pid + '/stat', 'utf8').split(' ')[2] === 'Z'; }
      catch { return true; }
    })).toBe(true);
  });
  test('呼び出し元Nodeの終了時にも検査用process groupを停止する', async () => {
    const f = fixture();
    const pidFile = path.join(f.root, 'pids');
    fs.writeFileSync(path.join(f.root, '.zshrc'), [
      'sleep 10 &', 'print -r -- "$$ $!" > ' + JSON.stringify(pidFile), 'wait',
    ].join('\n'));
    const modulePath = path.resolve(__dirname, '../../dist/diagnostics/environment.js');
    const source = 'const {readShellEnvironment}=require(' + JSON.stringify(modulePath) +
      '); void readShellEnvironment({timeout:10000}); process.on("message",()=>process.exit(0));';
    const child = spawn(process.execPath, ['-e', source], { env: f.env, stdio: ['ignore', 'ignore', 'ignore', 'ipc'] });
    let pids: string[] = [];
    try {
      await expect.poll(() => fs.existsSync(pidFile), { timeout: 3000 }).toBe(true);
      pids = fs.readFileSync(pidFile, 'utf8').trim().split(' ');
      child.send('exit');
      await expect.poll(() => child.exitCode, { timeout: 3000 }).toBe(0);
      await expect.poll(() => pids.every(pid => {
        try { return fs.readFileSync('/proc/' + pid + '/stat', 'utf8').split(' ')[2] === 'Z'; }
        catch { return true; }
      }), { timeout: 1500 }).toBe(true);
    } finally {
      if (child.exitCode === null) child.kill('SIGKILL');
      const leader = pids[0];
      if (leader) { try { process.kill(-Number(leader), 'SIGKILL'); } catch {} }
    }
  }, 10000);
  test('過大な起動出力を制限する', async () => {
    const f = fixture();
    expect(await readShellEnvironment({ env: f.env, maxBytes: 8 })).toEqual({ kind: 'unavailable', reason: 'output-limit' });
  });
  test('通常の起動出力を読み飛ばし、不完全な結果は採用しない', () => {
    const zero = String.fromCharCode(0);
    const result = parseShellEnvironment(['startup\n__ZLS_ENV_V1__', 'command', 'a b', '__ZLS_ENV_END__', ''].join(zero));
    expect(result.kind === 'available' && result.commands.has('a b')).toBe(true);
    expect(parseShellEnvironment('incomplete')).toEqual({ kind: 'unavailable', reason: 'invalid-output' });
    expect(parseShellEnvironment(['__ZLS_ENV_V1__', 'command', 'x', ''].join(zero)).kind).toBe('unavailable');
  });
});

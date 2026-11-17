import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createIOState } from '../../src/util/ioState';

/** テストが作った一時ディレクトリだけを、I/O資源として登録して後始末する。 */
export function createTemporaryDirectories() {
  const directories = createIOState<readonly string[]>([]);
  const track = (directory: string): void =>
    directories.update((previous) => [...previous, directory]);
  return {
    track,
    create(prefix: string): string {
      const directory = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
      track(directory);
      return directory;
    },
    cleanup(): void {
      const pending = directories.read();
      directories.replace([]);
      for (const directory of pending) {
        fs.rmSync(directory, { recursive: true, force: true });
      }
    },
  };
}

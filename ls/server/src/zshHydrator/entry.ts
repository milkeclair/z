import fs from 'fs';
import path from 'path';
import { createZshFileHydration, type ZshFileHydration } from './fileHydration';
import type { ZshHydrator } from './hydrator';
import type { DocumentInput } from './inputs';

type DiskFingerprint = {
  readonly kind: 'disk';
  readonly mtimeMs: number;
  readonly ctimeMs: number;
  readonly size: number;
};

type DocumentFingerprint = {
  readonly kind: 'document';
  readonly content: string;
  readonly version: number;
  readonly length: number;
};

type Fingerprint = DiskFingerprint | DocumentFingerprint;

export type ZshHydrationEntry = ZshFileHydration & {
  readonly fingerprint: Fingerprint;
};

export function isRegularFile(filename: string): boolean {
  try {
    return fs.statSync(filename).isFile();
  } catch (error) {
    if (
      error instanceof Error &&
      'code' in error &&
      (error.code === 'ENOENT' || error.code === 'ENOTDIR' || error.code === 'EISDIR')
    ) {
      return false;
    }

    throw error;
  }
}

export function hydrateDiskFile({
  previous,
  projectRoot,
  relativePath,
  maxBytes = Infinity,
}: {
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly relativePath: string;
  readonly maxBytes?: number;
}): ZshHydrationEntry | null {
  try {
    const absolutePath = path.resolve(projectRoot, relativePath);
    const stat = fs.statSync(absolutePath);

    if (!stat.isFile() || stat.size > maxBytes) {
      return null;
    }

    const fingerprint: DiskFingerprint = {
      kind: 'disk',
      mtimeMs: stat.mtimeMs,
      ctimeMs: stat.ctimeMs,
      size: stat.size,
    };
    const cached = previous.files.get(relativePath);

    if (cached && sameFingerprint(cached.fingerprint, fingerprint)) {
      return cached;
    } else {
      return {
        ...createZshFileHydration({
          sourceFile: absolutePath,
          file: relativePath,
          content: fs.readFileSync(absolutePath, 'utf-8'),
          options: previous.options,
        }),
        fingerprint,
      };
    }
  } catch (error) {
    if (
      error instanceof Error &&
      'code' in error &&
      (error.code === 'ENOENT' || error.code === 'ENOTDIR' || error.code === 'EISDIR')
    ) {
      return null;
    }

    throw error;
  }
}

export function hydrateOpenDocument({
  previous,
  input,
}: {
  readonly previous: ZshHydrator;
  readonly input: DocumentInput;
}): ZshHydrationEntry {
  const content = input.document.getText();
  const fingerprint: DocumentFingerprint = {
    kind: 'document',
    content,
    version: input.document.version,
    length: content.length,
  };
  const cached = previous.files.get(input.relativePath);

  if (cached && sameFingerprint(cached.fingerprint, fingerprint)) {
    return cached;
  } else {
    return {
      ...createZshFileHydration({
        sourceFile: input.absolutePath,
        file: input.relativePath,
        content,
        options: previous.options,
      }),
      fingerprint,
    };
  }
}

function sameFingerprint(left: Fingerprint, right: Fingerprint): boolean {
  if (left.kind !== right.kind) {
    return false;
  } else if (left.kind === 'disk' && right.kind === 'disk') {
    return (
      left.mtimeMs === right.mtimeMs && left.ctimeMs === right.ctimeMs && left.size === right.size
    );
  } else if (left.kind === 'document' && right.kind === 'document') {
    return (
      left.version === right.version &&
      left.length === right.length &&
      left.content === right.content
    );
  } else {
    return false;
  }
}

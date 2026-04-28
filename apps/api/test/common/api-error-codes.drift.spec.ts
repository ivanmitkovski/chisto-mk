/// <reference types="jest" />

import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { ALL_STABLE_API_ERROR_CODES, isRegisteredApiErrorCode } from '../../src/common/errors/codes';

function walkTsFiles(dir: string, acc: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) {
      walkTsFiles(full, acc);
    } else if (name.endsWith('.ts') && !name.endsWith('.d.ts')) {
      acc.push(full);
    }
  }
  return acc;
}

const CODE_LITERAL_RE = /\bcode:\s*'([A-Z][A-Z0-9_]*)'/g;

describe('API error code registry drift', () => {
  it('every code: literal under events, event-chat, cleanup-events, gamification, sites is registered in codes.ts', () => {
    const roots = [
      join(__dirname, '../../src/events'),
      join(__dirname, '../../src/event-chat'),
      join(__dirname, '../../src/cleanup-events'),
      join(__dirname, '../../src/gamification'),
      join(__dirname, '../../src/sites'),
    ];
    const files = roots.flatMap((r) => walkTsFiles(r));
    const found = new Set<string>();

    for (const file of files) {
      const text = readFileSync(file, 'utf8');
      let m: RegExpExecArray | null;
      CODE_LITERAL_RE.lastIndex = 0;
      while ((m = CODE_LITERAL_RE.exec(text)) !== null) {
        found.add(m[1]);
      }
    }

    const missing = [...found].filter((c) => !isRegisteredApiErrorCode(c)).sort();
    expect({
      missing,
      mergedCount: ALL_STABLE_API_ERROR_CODES.length,
    }).toEqual({
      missing: [],
      mergedCount: ALL_STABLE_API_ERROR_CODES.length,
    });
  });
});

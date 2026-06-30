import { beforeEach, describe, expect, it, vi } from 'vitest';
import {
  clearRecentCommands,
  filterRecentIds,
  loadRecentCommandIds,
  recordRecentCommand,
} from './recents';

describe('command palette recents', () => {
  const storage = new Map<string, string>();

  beforeEach(() => {
    storage.clear();
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => storage.get(key) ?? null,
      setItem: (key: string, value: string) => {
        storage.set(key, value);
      },
      removeItem: (key: string) => {
        storage.delete(key);
      },
    });
    clearRecentCommands();
  });

  it('stores and loads recent command ids', () => {
    recordRecentCommand('go-reports');
    recordRecentCommand('go-users');
    expect(loadRecentCommandIds()).toEqual(['go-users', 'go-reports']);
  });

  it('dedupes and caps at five items', () => {
    for (const id of ['a', 'b', 'c', 'd', 'e', 'f']) {
      recordRecentCommand(id);
    }
    recordRecentCommand('b');
    const ids = loadRecentCommandIds();
    expect(ids.length).toBeLessThanOrEqual(5);
    expect(ids[0]).toBe('b');
  });

  it('filters unknown or disallowed ids', () => {
    const allowed = new Set(['go-reports']);
    expect(filterRecentIds(['go-reports', 'missing'], allowed)).toEqual(['go-reports']);
  });
});

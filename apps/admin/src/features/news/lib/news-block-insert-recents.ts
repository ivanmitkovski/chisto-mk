import type { BlockInsertType } from './news-block-insert-config';

const STORAGE_KEY = 'news:block-insert-recents';
const MAX_RECENTS = 5;

export function readBlockInsertRecents(): BlockInsertType[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((item): item is BlockInsertType => typeof item === 'string');
  } catch {
    return [];
  }
}

export function recordBlockInsertRecent(type: BlockInsertType): void {
  if (typeof window === 'undefined') return;
  const next = [type, ...readBlockInsertRecents().filter((item) => item !== type)].slice(0, MAX_RECENTS);
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    // Storage may be unavailable in private mode.
  }
}

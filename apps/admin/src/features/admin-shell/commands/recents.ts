const RECENTS_STORAGE_KEY = 'chisto:command-palette-recents';
const RECENTS_SCHEMA_VERSION = 1;
const MAX_RECENTS = 5;

type RecentsPayload = {
  v: number;
  items: { id: string; usedAt: number }[];
};

function getStorage(): Storage | null {
  if (typeof globalThis.localStorage === 'undefined') return null;
  return globalThis.localStorage;
}

function readPayload(): RecentsPayload {
  const storage = getStorage();
  if (!storage) {
    return { v: RECENTS_SCHEMA_VERSION, items: [] };
  }

  try {
    const raw = storage.getItem(RECENTS_STORAGE_KEY);
    if (!raw) return { v: RECENTS_SCHEMA_VERSION, items: [] };
    const parsed = JSON.parse(raw) as RecentsPayload;
    if (parsed.v !== RECENTS_SCHEMA_VERSION || !Array.isArray(parsed.items)) {
      return { v: RECENTS_SCHEMA_VERSION, items: [] };
    }
    return parsed;
  } catch {
    return { v: RECENTS_SCHEMA_VERSION, items: [] };
  }
}

function writePayload(payload: RecentsPayload): void {
  const storage = getStorage();
  if (!storage) return;
  storage.setItem(RECENTS_STORAGE_KEY, JSON.stringify(payload));
}

export function loadRecentCommandIds(): string[] {
  return readPayload()
    .items.sort((a, b) => b.usedAt - a.usedAt)
    .map((item) => item.id);
}

export function recordRecentCommand(commandId: string): void {
  const payload = readPayload();
  const now = Date.now();
  const without = payload.items.filter((item) => item.id !== commandId);
  const next = [{ id: commandId, usedAt: now }, ...without].slice(0, MAX_RECENTS);
  writePayload({ v: RECENTS_SCHEMA_VERSION, items: next });
}

export function clearRecentCommands(): void {
  writePayload({ v: RECENTS_SCHEMA_VERSION, items: [] });
}

export function filterRecentIds(ids: string[], allowedIds: Set<string>): string[] {
  return ids.filter((id) => allowedIds.has(id));
}

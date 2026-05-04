/** Socket.IO CORS allowlist — shared by all WS namespaces (chat, reports-owner, …). */
export function resolveSocketIoCorsOrigin(): boolean | string | string[] {
  const raw = process.env.CHAT_WS_CORS_ORIGINS?.trim();
  if (raw) {
    const list = raw.split(',').map((s) => s.trim()).filter(Boolean);
    return list.length ? list : '*';
  }
  if (process.env.NODE_ENV === 'production') {
    throw new Error('CHAT_WS_CORS_ORIGINS must be set in production (comma-separated allowlist)');
  }
  return '*';
}

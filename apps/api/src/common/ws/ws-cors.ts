import { parseWsCorsAllowlist } from './parse-ws-cors-allowlist';

/** Socket.IO CORS allowlist — shared by all WS namespaces (chat, reports-owner, …). */
export function resolveSocketIoCorsOrigin(): boolean | string | string[] {
  return parseWsCorsAllowlist(process.env.CHAT_WS_CORS_ORIGINS, 'CHAT_WS_CORS_ORIGINS');
}

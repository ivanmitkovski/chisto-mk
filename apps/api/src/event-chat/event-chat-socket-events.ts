/** Maps internal chat bus event types to Socket.IO event names. */
export function chatStreamTypeToSocketEvent(sseType: string): string {
  const map: Record<string, string> = {
    message_created: 'message:created',
    message_deleted: 'message:deleted',
    message_edited: 'message:edited',
    message_pinned: 'message:pinned',
    message_unpinned: 'message:unpinned',
    typing_update: 'typing:update',
    read_cursor_updated: 'read_cursor:updated',
  };
  return map[sseType] ?? sseType;
}

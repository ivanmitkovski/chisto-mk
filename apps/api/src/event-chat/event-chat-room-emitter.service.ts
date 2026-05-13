import { Injectable, Logger } from '@nestjs/common';
import type { Server } from 'socket.io';

/**
 * Fan-out from {@link EventChatSseService} to Socket.IO without `forwardRef` into {@link EventChatGateway}.
 */
@Injectable()
export class EventChatRoomEmitterService {
  private readonly logger = new Logger(EventChatRoomEmitterService.name);
  private server: Server | null = null;

  attachServer(server: Server): void {
    this.server = server;
  }

  isReady(): boolean {
    return this.server != null;
  }

  /**
   * SSE / internal events use snake_case (`message_created`). The mobile Socket.IO client
   * listens for colon-separated names (`message:created`) — map here so both transports align.
   */
  private toSocketIoEventName(sseType: string): string {
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

  emitToRoom(eventId: string, eventType: string, payload: unknown): void {
    if (!this.server) {
      this.logger.warn(`emitToRoom skipped (${eventType}): Socket.IO server not attached yet`);
      return;
    }
    const room = `event:${eventId}`;
    const socketEvent = this.toSocketIoEventName(eventType);
    void this.server
      .in(room)
      .fetchSockets()
      .then((sockets) => {
        this.logger.debug(`emit ${socketEvent} room=${room} sockets=${sockets.length}`);
      })
      .catch((err: unknown) => {
        this.logger.debug(`emit ${socketEvent} room=${room} socket count failed: ${String(err)}`);
      });
    this.server.to(room).emit(socketEvent, payload);
  }
}

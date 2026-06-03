import { Injectable, Logger } from '@nestjs/common';
import type { Server } from 'socket.io';
import { chatStreamTypeToSocketEvent } from '../gateways/event-chat-socket-events';

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

  emitToRoom(eventId: string, eventType: string, payload: unknown): void {
    if (!this.server) {
      this.logger.warn(`emitToRoom skipped (${eventType}): Socket.IO server not attached yet`);
      return;
    }
    const room = `event:${eventId}`;
    const socketEvent = chatStreamTypeToSocketEvent(eventType);
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

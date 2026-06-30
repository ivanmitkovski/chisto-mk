import { Injectable, Logger } from '@nestjs/common';
import type { Server } from 'socket.io';

/**
 * Bridges {@link EventLiveImpactService} / check-in redemption to Socket.IO rooms without a DI
 * cycle on {@link EventCheckInGateway}. The gateway attaches the server once in `afterInit`.
 */
@Injectable()
export class EventCheckInRoomEmitterService {
  private readonly logger = new Logger(EventCheckInRoomEmitterService.name);
  private server: Server | null = null;

  attachServer(server: Server): void {
    this.server = server;
  }

  emitToRoom(eventId: string, eventType: string, payload: unknown): void {
    if (!this.server) {
      this.logger.warn(`emitToRoom skipped (${eventType}): Socket.IO server not attached yet`);
      return;
    }
    const room = `checkin:${eventId}`;
    void this.server
      .in(room)
      .fetchSockets()
      .then((sockets) => {
        this.logger.debug(`emit ${eventType} room=${room} sockets=${sockets.length}`);
      })
      .catch((err: unknown) => {
        this.logger.debug(`emit ${eventType} room=${room} socket count failed: ${String(err)}`);
      });
    this.server.to(room).emit(eventType, payload);
  }
}

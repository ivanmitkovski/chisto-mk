import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Server, Socket } from 'socket.io';
import { Subscription } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';
import { authenticateSocketUser } from '../../common/ws/authenticate-socket-user';
import { resolveSocketIoCorsOrigin } from '../../common/ws/ws-cors';
import { ReportsOwnerEventsService } from '../reports-owner-events.service';
import type { OwnerReportEvent } from '../reports-owner-events.types';

interface ReportsOwnerSocketData {
  userId?: string;
}

@WebSocketGateway({
  namespace: '/reports-owner',
  cors: { origin: resolveSocketIoCorsOrigin() },
  pingInterval: 25_000,
  pingTimeout: 25_000,
})
export class ReportsOwnerGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ReportsOwnerGateway.name);
  private readonly subsBySocketId = new Map<string, Subscription>();
  /** At most one owner stream per user; new tab/device disconnects the previous socket. */
  private readonly socketIdByUserId = new Map<string, string>();

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly reportsOwnerEvents: ReportsOwnerEventsService,
  ) {}

  afterInit(_server: Server): void {
    this.logger.log('Reports owner WebSocket gateway initialized');
  }

  async handleConnection(client: Socket): Promise<void> {
    try {
      const { userId } = await authenticateSocketUser(client, this.config, this.prisma);
      (client.data as ReportsOwnerSocketData).userId = userId;

      const previousSocketId = this.socketIdByUserId.get(userId);
      if (previousSocketId && previousSocketId !== client.id) {
        const previous = this.server.sockets.sockets.get(previousSocketId);
        previous?.disconnect(true);
        this.subsBySocketId.get(previousSocketId)?.unsubscribe();
        this.subsBySocketId.delete(previousSocketId);
      }
      this.socketIdByUserId.set(userId, client.id);

      const sub = this.reportsOwnerEvents.getEventsForOwner(userId).subscribe({
        next: (evt: OwnerReportEvent) => {
          client.emit('report_event', evt);
        },
        error: (err: unknown) => {
          this.logger.warn(`owner events stream error user=${userId}: ${String(err)}`);
        },
      });
      this.subsBySocketId.set(client.id, sub);

      this.logger.debug(`reports-owner connected user=${userId} socket=${client.id}`);
    } catch (error) {
      this.logger.warn(`reports-owner WS auth failed: ${String(error)}`);
      client.emit('error', { code: 'AUTH_FAILED', message: 'Authentication failed' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const sub = this.subsBySocketId.get(client.id);
    sub?.unsubscribe();
    this.subsBySocketId.delete(client.id);

    const userId = (client.data as ReportsOwnerSocketData).userId;
    if (userId && this.socketIdByUserId.get(userId) === client.id) {
      this.socketIdByUserId.delete(userId);
    }
    if (userId) {
      this.logger.debug(`reports-owner disconnected user=${userId} socket=${client.id}`);
    }
  }
}

import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../../prisma/prisma.service';
import { authenticateSocketUser } from '../../common/ws/authenticate-socket-user';
import { resolveSocketIoCorsOrigin } from '../../common/ws/ws-cors';
import { NotificationsRoomEmitterService } from '../services/notifications-room-emitter.service';
import { FeatureFlagsService } from '../../feature-flags/services/feature-flags.service';

interface SocketData {
  userId?: string;
}

@WebSocketGateway({
  namespace: '/notifications',
  cors: { origin: resolveSocketIoCorsOrigin() },
  pingInterval: 25_000,
  pingTimeout: 25_000,
})
export class NotificationsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect, OnModuleDestroy
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(NotificationsGateway.name);
  private badgeSyncInterval: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly roomEmitter: NotificationsRoomEmitterService,
    private readonly featureFlags: FeatureFlagsService,
  ) {}

  afterInit(server: Server): void {
    this.roomEmitter.attachServer(server);
    this.logger.log('Notifications WebSocket gateway initialized');
    this.badgeSyncInterval = setInterval(() => {
      void this.broadcastBadgeSyncToConnectedUsers();
    }, 60_000);
  }

  async handleConnection(client: Socket): Promise<void> {
    try {
      const enabled = await this.featureFlags.isPushRealtimeSocketEnabled();
      if (!enabled) {
        client.emit('error', { code: 'FEATURE_DISABLED', message: 'Realtime notifications disabled' });
        client.disconnect(true);
        return;
      }

      const { userId } = await authenticateSocketUser(client, this.config, this.prisma);
      (client.data as SocketData).userId = userId;
      await client.join(`user:${userId}`);

      const unreadCount = await this.prisma.userNotification.count({
        where: { userId, isRead: false, archivedAt: null },
      });
      client.emit('badge.sync', { unreadCount });

      this.logger.debug(`Notifications WS connected: ${userId} (${client.id})`);
    } catch (error) {
      this.logger.warn(`Notifications WS auth failed: ${String(error)}`);
      client.emit('error', { code: 'AUTH_FAILED', message: 'Authentication failed' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const userId = (client.data as SocketData)?.userId;
    if (userId) {
      this.logger.debug(`Notifications WS disconnected: ${userId} (${client.id})`);
    }
  }

  onModuleDestroy(): void {
    if (this.badgeSyncInterval != null) {
      clearInterval(this.badgeSyncInterval);
      this.badgeSyncInterval = null;
    }
  }

  private async broadcastBadgeSyncToConnectedUsers(): Promise<void> {
    if (!this.server || !this.roomEmitter.isReady()) return;
    const enabled = await this.featureFlags.isPushRealtimeSocketEnabled();
    if (!enabled) return;

    const sockets = await this.server.fetchSockets();
    const userIds = new Set<string>();
    for (const socket of sockets) {
      const userId = (socket.data as SocketData)?.userId;
      if (userId) userIds.add(userId);
    }
    for (const userId of userIds) {
      const unreadCount = await this.prisma.userNotification.count({
        where: { userId, isRead: false, archivedAt: null },
      });
      this.roomEmitter.emitBadgeSync(userId, unreadCount);
    }
  }
}

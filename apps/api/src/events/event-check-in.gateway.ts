import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';
import { UserStatus } from '../generated/prisma';
import * as jwt from 'jsonwebtoken';

interface CheckInSocketData {
  userId: string;
  displayName: string;
}

function resolveCheckInWsCorsOrigin(): boolean | string | string[] {
  const raw = process.env.CHECKIN_WS_CORS_ORIGINS?.trim() || process.env.CHAT_WS_CORS_ORIGINS?.trim();
  if (raw) {
    const list = raw.split(',').map((s) => s.trim()).filter(Boolean);
    return list.length ? list : '*';
  }
  return process.env.NODE_ENV === 'production' ? true : '*';
}

/**
 * Real-time check-in room fan-out (`join` → `checkin:{eventId}`).
 *
 * **Visibility vs event chat** — [`EventChatAccessService.assertCanAccessEventChat`] only exposes events that are
 * **approved** or owned by the current user (organizer), so draft listings do not appear in social/chat UX.
 * Here, `join` allows any existing `CleanupEvent` id when the socket user is **organizer or participant**,
 * so organizers and joined volunteers still receive check-in signals for operational flows (including events
 * that are not yet public in chat). `userId` always comes from the verified JWT, never from client payloads.
 */
@WebSocketGateway({
  namespace: '/check-in',
  cors: { origin: resolveCheckInWsCorsOrigin() },
  pingInterval: 25_000,
  pingTimeout: 25_000,
})
export class EventCheckInGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(EventCheckInGateway.name);

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  afterInit(server: Server): void {
    void server;
    this.logger.log('Check-in WebSocket gateway initialized');
  }

  async handleConnection(client: Socket): Promise<void> {
    try {
      const authHeader = client.handshake.headers.authorization;
      let tokenFromHeader: string | undefined;
      if (typeof authHeader === 'string') {
        const match = authHeader.match(/^Bearer\s+(.+)$/i);
        tokenFromHeader = match?.[1]?.trim();
      }
      const token =
        (client.handshake.auth?.token as string) || tokenFromHeader;

      if (!token) {
        throw new UnauthorizedException('Missing token');
      }

      const secret = this.config.get<string>('JWT_SECRET');
      if (!secret) {
        throw new Error('JWT_SECRET not configured');
      }

      const payload = jwt.verify(token, secret) as {
        sub: string;
        email: string;
      };

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, firstName: true, lastName: true, status: true },
      });

      if (!user || user.status !== UserStatus.ACTIVE) {
        throw new UnauthorizedException('User not active');
      }

      (client.data as CheckInSocketData).userId = user.id;
      (client.data as CheckInSocketData).displayName =
        `${user.firstName} ${user.lastName}`.trim();

      this.logger.debug(`Check-in WS connected: ${user.id} (${client.id})`);
    } catch (error) {
      this.logger.warn(`Check-in WS auth failed: ${String(error)}`);
      client.emit('error', { code: 'AUTH_FAILED', message: 'Authentication failed' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const userId = (client.data as CheckInSocketData)?.userId;
    if (userId) {
      this.logger.debug(`Check-in WS disconnected: ${userId} (${client.id})`);
    }
  }

  private coerceMessageBody(data: unknown): unknown {
    if (data == null) {
      return data;
    }
    if (typeof data === 'string') {
      const t = data.trim();
      if (t.startsWith('{') || t.startsWith('[')) {
        try {
          return JSON.parse(data) as unknown;
        } catch {
          return data;
        }
      }
      return data;
    }
    if (Array.isArray(data) && data.length === 1) {
      return this.coerceMessageBody(data[0]);
    }
    return data;
  }

  private parseEventId(data: unknown): string | null {
    const coerced = this.coerceMessageBody(data);
    if (coerced === null || typeof coerced !== 'object') {
      return null;
    }
    const raw = (coerced as { eventId?: unknown }).eventId;
    return typeof raw === 'string' && raw.length > 0 ? raw : null;
  }

  @SubscribeMessage('join')
  async handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const eventId = this.parseEventId(data);
    if (!eventId) {
      this.logger.warn(`check-in join: invalid payload type=${typeof data}`);
      return;
    }
    const userId = (client.data as CheckInSocketData).userId;
    if (!userId) {
      return;
    }

    const allowed = await this.isEventParticipantOrOrganizer(userId, eventId);
    if (!allowed) {
      client.emit('error', {
        code: 'CHECK_IN_FORBIDDEN',
        message: 'Cannot join this check-in room',
      });
      return;
    }

    const room = `checkin:${eventId}`;
    await client.join(room);
    this.logger.debug(`${userId} joined ${room}`);
  }

  @SubscribeMessage('leave')
  async handleLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const eventId = this.parseEventId(data);
    if (!eventId) {
      return;
    }
    const room = `checkin:${eventId}`;
    await client.leave(room);
  }

  emitToRoom(eventId: string, eventType: string, payload: unknown): void {
    const room = `checkin:${eventId}`;
    void this.server
      .in(room)
      .fetchSockets()
      .then((sockets) => {
        this.logger.debug(
          `emit ${eventType} room=${room} sockets=${sockets.length}`,
        );
      })
      .catch((err: unknown) => {
        this.logger.debug(
          `emit ${eventType} room=${room} socket count failed: ${String(err)}`,
        );
      });
    this.server.to(room).emit(eventType, payload);
  }

  private async isEventParticipantOrOrganizer(
    userId: string,
    eventId: string,
  ): Promise<boolean> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId },
      select: { organizerId: true },
    });
    if (event?.organizerId === userId) {
      return true;
    }
    const participant = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
      select: { id: true },
    });
    return participant != null;
  }
}

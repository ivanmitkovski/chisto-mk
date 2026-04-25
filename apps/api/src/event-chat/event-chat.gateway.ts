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
import { EventChatAccessService } from './event-chat-access.service';

interface SocketData {
  userId?: string;
  displayName?: string;
}

function resolveChatWsCorsOrigin(): boolean | string | string[] {
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

@WebSocketGateway({
  namespace: '/chat',
  cors: { origin: resolveChatWsCorsOrigin() },
  pingInterval: 25_000,
  // Avoid spurious disconnects on slow mobile links (default 20s is often fine; 10s was tight).
  pingTimeout: 25_000,
})
export class EventChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private static readonly WS_TYPING_MIN_INTERVAL_MS = 2500;
  private static readonly WS_JOIN_WINDOW_MS = 10_000;
  private static readonly WS_JOIN_MAX_PER_WINDOW = 20;

  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(EventChatGateway.name);
  private readonly lastWsTypingEmitAt = new Map<string, number>();
  /** Per-socket join timestamps (ms) for sliding-window rate limit. */
  private readonly joinTimestampsBySocketId = new Map<string, number[]>();

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly eventChatAccess: EventChatAccessService,
  ) {}

  afterInit(_server: Server): void {
    this.logger.log('Chat WebSocket gateway initialized');
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

      const payload = jwt.verify(token, secret, { algorithms: ['HS256'] }) as {
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

      (client.data as SocketData).userId = user.id;
      (client.data as SocketData).displayName = `${user.firstName} ${user.lastName}`.trim();

      this.logger.debug(`Client connected: ${user.id} (${client.id})`);
    } catch (error) {
      this.logger.warn(`WS auth failed: ${String(error)}`);
      client.emit('error', { code: 'AUTH_FAILED', message: 'Authentication failed' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const userId = (client.data as SocketData)?.userId;
    if (userId) {
      this.logger.debug(`Client disconnected: ${userId} (${client.id})`);
    }
    this.joinTimestampsBySocketId.delete(client.id);
  }

  /** Normalize client payloads (string JSON, or Socket.IO single-arg array). */
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

  private assertJoinRateOk(clientId: string): boolean {
    const now = Date.now();
    const windowStart = now - EventChatGateway.WS_JOIN_WINDOW_MS;
    const prev = this.joinTimestampsBySocketId.get(clientId) ?? [];
    const kept = prev.filter((t) => t > windowStart);
    if (kept.length >= EventChatGateway.WS_JOIN_MAX_PER_WINDOW) {
      return false;
    }
    kept.push(now);
    this.joinTimestampsBySocketId.set(clientId, kept);
    return true;
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
      this.logger.warn(`join: invalid payload type=${typeof data}`);
      return;
    }
    const userId = (client.data as SocketData).userId;
    if (!userId) {
      client.emit('error', {
        code: 'EVENT_CHAT_WS_AUTH_PENDING',
        message: 'Authentication not finished; retry join after connected',
      });
      return;
    }
    if (!this.assertJoinRateOk(client.id)) {
      client.emit('error', {
        code: 'EVENT_CHAT_WS_RATE_LIMIT',
        message: 'Too many join requests; slow down',
      });
      return;
    }
    try {
      await this.eventChatAccess.assertCanAccessEventChat(userId, eventId);
    } catch {
      client.emit('error', {
        code: 'EVENT_CHAT_FORBIDDEN',
        message: 'Cannot join this chat room',
      });
      return;
    }
    const room = `event:${eventId}`;
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
    const room = `event:${eventId}`;
    await client.leave(room);
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const coerced = this.coerceMessageBody(data);
    if (coerced === null || typeof coerced !== 'object') {
      return;
    }
    const o = coerced as { eventId?: unknown; typing?: unknown };
    const eventId = typeof o.eventId === 'string' && o.eventId.length > 0 ? o.eventId : null;
    if (!eventId) {
      return;
    }
    const socketData = client.data as SocketData;
    if (!socketData.userId) {
      client.emit('error', {
        code: 'EVENT_CHAT_WS_AUTH_PENDING',
        message: 'Authentication not finished',
      });
      return;
    }
    try {
      await this.eventChatAccess.assertCanAccessEventChat(socketData.userId, eventId);
    } catch {
      client.emit('error', {
        code: 'EVENT_CHAT_FORBIDDEN',
        message: 'Cannot send typing to this chat room',
      });
      return;
    }
    const room = `event:${eventId}`;
    const typing = o.typing === true;
    const throttleKey = `${socketData.userId}:${eventId}`;
    const now = Date.now();
    if (typing) {
      const last = this.lastWsTypingEmitAt.get(throttleKey) ?? 0;
      if (now - last < EventChatGateway.WS_TYPING_MIN_INTERVAL_MS) {
        return;
      }
      this.lastWsTypingEmitAt.set(throttleKey, now);
    } else {
      this.lastWsTypingEmitAt.delete(throttleKey);
    }
    client.to(room).emit('typing:update', {
      eventId,
      userId: socketData.userId,
      displayName: socketData.displayName,
      typing,
    });
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
    const room = `event:${eventId}`;
    const socketEvent = this.toSocketIoEventName(eventType);
    void this.server
      .in(room)
      .fetchSockets()
      .then((sockets) => {
        this.logger.debug(
          `emit ${socketEvent} room=${room} sockets=${sockets.length}`,
        );
      })
      .catch((err: unknown) => {
        this.logger.debug(`emit ${socketEvent} room=${room} socket count failed: ${String(err)}`);
      });
    this.server.to(room).emit(socketEvent, payload);
  }
}

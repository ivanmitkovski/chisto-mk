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
import { authenticateSocketUser } from '../common/ws/authenticate-socket-user';
import { parseWsCorsAllowlist } from '../common/ws/parse-ws-cors-allowlist';
import { PrismaService } from '../prisma/prisma.service';
import { CheckInRepository } from './check-in.repository';
import { EventCheckInRoomEmitterService } from './event-check-in-room-emitter.service';
import { EventLiveImpactService } from './event-live-impact.service';

interface CheckInSocketData {
  userId: string;
  displayName: string;
}

function resolveCheckInWsCorsOrigin(): boolean | string | string[] {
  const merged =
    process.env.CHECKIN_WS_CORS_ORIGINS?.trim() || process.env.CHAT_WS_CORS_ORIGINS?.trim();
  return parseWsCorsAllowlist(merged, 'CHECKIN_WS_CORS_ORIGINS');
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
    private readonly checkInRepository: CheckInRepository,
    private readonly liveImpact: EventLiveImpactService,
    private readonly checkInRoomEmitter: EventCheckInRoomEmitterService,
  ) {}

  afterInit(server: Server): void {
    this.checkInRoomEmitter?.attachServer(server);
    this.logger.log('Check-in WebSocket gateway initialized');
  }

  async handleConnection(client: Socket): Promise<void> {
    try {
      const user = await authenticateSocketUser(client, this.config, this.prisma);
      (client.data as CheckInSocketData).userId = user.userId;
      (client.data as CheckInSocketData).displayName = user.displayName;

      this.logger.debug(`Check-in WS connected: ${user.userId} (${client.id})`);
    } catch (error) {
      this.logger.warn(`Check-in WS auth failed: ${String(error)}`);
      const fallback = { code: 'AUTH_FAILED', message: 'Authentication failed' } as const;
      if (error instanceof UnauthorizedException) {
        const body = error.getResponse();
        if (
          typeof body === 'object' &&
          body !== null &&
          'code' in body &&
          'message' in body &&
          typeof (body as { code: unknown }).code === 'string' &&
          typeof (body as { message: unknown }).message === 'string'
        ) {
          client.emit('error', {
            code: (body as { code: string }).code,
            message: (body as { message: string }).message,
          });
        } else {
          client.emit('error', {
            code: 'CHECK_IN_UNAUTHORIZED',
            message: typeof body === 'string' ? body : fallback.message,
          });
        }
      } else {
        client.emit('error', { code: fallback.code, message: fallback.message });
      }
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

  private parseLiveImpactPublish(
    data: unknown,
  ): { eventId: string; reportedBagsCollected: number } | null {
    const coerced = this.coerceMessageBody(data);
    if (coerced === null || typeof coerced !== 'object') {
      return null;
    }
    const o = coerced as { eventId?: unknown; reportedBagsCollected?: unknown };
    const eventId = typeof o.eventId === 'string' && o.eventId.length > 0 ? o.eventId : null;
    if (eventId == null) {
      return null;
    }
    const bagsRaw = o.reportedBagsCollected;
    const reportedBagsCollected =
      typeof bagsRaw === 'number' && Number.isFinite(bagsRaw) ? bagsRaw : null;
    if (reportedBagsCollected == null) {
      return null;
    }
    return { eventId, reportedBagsCollected };
  }

  @SubscribeMessage('live_impact_publish')
  async handleLiveImpactPublish(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const parsed = this.parseLiveImpactPublish(data);
    if (parsed == null) {
      return;
    }
    const userId = (client.data as CheckInSocketData).userId;
    if (!userId) {
      return;
    }
    await this.liveImpact.publishFromOrganizerSocket(
      parsed.eventId,
      userId,
      parsed.reportedBagsCollected,
    );
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

    const allowed = await this.checkInRepository.isEventParticipantOrOrganizer(
      userId,
      eventId,
    );
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
    this.checkInRoomEmitter.emitToRoom(eventId, eventType, payload);
  }

}

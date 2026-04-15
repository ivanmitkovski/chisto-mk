import { Inject, Injectable, Logger, OnModuleDestroy, forwardRef } from '@nestjs/common';
import Redis from 'ioredis';
import { Observable, Subject } from 'rxjs';
import { EventChatGateway } from './event-chat.gateway';
import { EventChatClusterConfig } from './event-chat-cluster.config';

export type ChatStreamEventType =
  | 'message_created'
  | 'message_deleted'
  | 'message_edited'
  | 'message_pinned'
  | 'message_unpinned'
  | 'typing_update'
  | 'read_cursor_updated';

/** When false, event is fan-out only (not stored in SSE replay buffer). */
export type ChatStreamEvent = {
  streamEventId: string;
  eventId: string;
  type: ChatStreamEventType;
  persistInReplay?: boolean;
  message?: Record<string, unknown>;
  messageId?: string;
  userId?: string;
  displayName?: string;
  typing?: boolean;
  lastReadMessageId?: string | null;
  lastReadMessageCreatedAt?: string | null;
};

type ChatRoom = {
  subject$: Subject<ChatStreamEvent>;
  replayBuffer: ChatStreamEvent[];
  seenStreamIds: Set<string>;
};

@Injectable()
export class EventChatSseService implements OnModuleDestroy {
  private static readonly REPLAY_LIMIT = 20;
  private static readonly REDIS_PREFIX = 'event-chat:';

  private readonly logger = new Logger(EventChatSseService.name);
  private readonly rooms = new Map<string, ChatRoom>();
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private publisher: Redis | null = null;
  private subscriber: Redis | null = null;
  private redisEnabled = false;
  private shuttingDown = false;
  private loggedMissingGateway = false;

  constructor(
    @Inject(forwardRef(() => EventChatGateway))
    private readonly gateway: EventChatGateway,
    private readonly clusterConfig: EventChatClusterConfig,
  ) {
    this.initRedis();
  }

  onModuleDestroy(): void {
    this.shuttingDown = true;
    void this.publisher?.quit().catch(() => undefined);
    void this.subscriber?.quit().catch(() => undefined);
    for (const room of this.rooms.values()) {
      room.subject$.complete();
    }
    this.rooms.clear();
  }

  getStream(eventId: string): Observable<ChatStreamEvent> {
    return this.getOrCreateRoom(eventId).subject$.asObservable();
  }

  getReplaySince(eventId: string, lastEventId?: string): ChatStreamEvent[] {
    const room = this.rooms.get(eventId);
    if (!room) {
      return [];
    }
    const normalized = lastEventId?.trim();
    if (!normalized) {
      return [];
    }
    const index = room.replayBuffer.findIndex((e) => e.streamEventId === normalized);
    if (index < 0) {
      return [];
    }
    return room.replayBuffer.slice(index + 1);
  }

  emitEvent(event: ChatStreamEvent): void {
    this.publishLocal(event);

    try {
      if (this.gateway?.server) {
        this.gateway.emitToRoom(event.eventId, event.type, event);
      } else if (!this.loggedMissingGateway) {
        this.loggedMissingGateway = true;
        this.logger.warn(
          'EventChatGateway server is not initialized; WebSocket room emits are skipped until the gateway is ready.',
        );
      }
    } catch (error) {
      this.logger.warn(`WS emit failed (SSE still active): ${String(error)}`);
    }

    if (!this.redisEnabled || !this.publisher) {
      return;
    }
    const channel = `${EventChatSseService.REDIS_PREFIX}${event.eventId}`;
    void this.publisher.publish(channel, JSON.stringify(event)).catch((error: unknown) => {
      this.logger.warn(`Redis publish failed (local SSE already emitted): ${String(error)}`);
    });
  }

  private getOrCreateRoom(eventId: string): ChatRoom {
    let room = this.rooms.get(eventId);
    if (!room) {
      room = {
        subject$: new Subject<ChatStreamEvent>(),
        replayBuffer: [],
        seenStreamIds: new Set<string>(),
      };
      this.rooms.set(eventId, room);
    }
    return room;
  }

  private publishLocal(event: ChatStreamEvent): void {
    const room = this.getOrCreateRoom(event.eventId);
    const persist = event.persistInReplay !== false;
    if (persist) {
      room.replayBuffer.push(event);
      room.seenStreamIds.add(event.streamEventId);
      while (room.replayBuffer.length > EventChatSseService.REPLAY_LIMIT) {
        const dropped = room.replayBuffer.shift();
        if (dropped) {
          room.seenStreamIds.delete(dropped.streamEventId);
        }
      }
    }
    queueMicrotask(() => {
      room!.subject$.next(event);
    });
  }

  private ingestFromRedis(eventId: string, payload: string): void {
    try {
      const parsed = JSON.parse(payload) as ChatStreamEvent;
      if (!parsed?.streamEventId || !parsed?.eventId || !parsed?.type) {
        return;
      }
      if (parsed.eventId !== eventId) {
        return;
      }
      const room = this.getOrCreateRoom(eventId);
      const persist = parsed.persistInReplay !== false;
      if (persist && room.seenStreamIds.has(parsed.streamEventId)) {
        return;
      }
      this.publishLocal(parsed);
      // With Socket.IO Redis adapter, the originating replica already clustered WS emit;
      // repeating here would duplicate deliveries to WebSocket clients.
      if (this.clusterConfig.socketIoClustered) {
        return;
      }
      try {
        if (this.gateway?.server) {
          this.gateway.emitToRoom(parsed.eventId, parsed.type, parsed);
        }
      } catch (error) {
        this.logger.warn(`WS emit from Redis fanout failed: ${String(error)}`);
      }
    } catch (error) {
      this.logger.warn(`Ignoring malformed chat event from Redis: ${String(error)}`);
    }
  }

  private initRedis(): void {
    if (!this.redisUrl) {
      if (process.env.NODE_ENV === 'production') {
        this.logger.log(
          'Event chat: REDIS_URL unset — fine for a single API instance; set REDIS_URL before scaling to 2+ tasks so chat/SSE/WebSocket fan out across replicas.',
        );
      }
      return;
    }
    try {
      this.publisher = new Redis(this.redisUrl);
      this.subscriber = new Redis(this.redisUrl);
      this.publisher.on('error', (error) => {
        this.logger.warn(`Event chat Redis publisher error: ${String(error)}`);
      });
      this.subscriber.on('error', (error) => {
        this.logger.warn(`Event chat Redis subscriber error: ${String(error)}`);
      });
      this.subscriber.on('pmessage', (_pattern, channel, payload) => {
        if (this.shuttingDown) {
          return;
        }
        if (!channel.startsWith(EventChatSseService.REDIS_PREFIX)) {
          return;
        }
        const eid = channel.slice(EventChatSseService.REDIS_PREFIX.length);
        if (!eid) {
          return;
        }
        this.ingestFromRedis(eid, payload);
      });
      void this.subscriber
        .psubscribe(`${EventChatSseService.REDIS_PREFIX}*`)
        .then(() => {
          this.redisEnabled = true;
          this.logger.log('Event chat Redis fanout enabled');
        })
        .catch((error: unknown) => {
          this.logger.warn(`Event chat Redis psubscribe failed: ${String(error)}`);
          this.redisEnabled = false;
        });
    } catch (error) {
      this.logger.warn(`Event chat Redis initialization failed: ${String(error)}`);
      this.redisEnabled = false;
      this.publisher = null;
      this.subscriber = null;
    }
  }
}

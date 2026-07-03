import {
  HttpException,
  MessageEvent as NestMessageEvent,
  UnauthorizedException,
} from '@nestjs/common';
import { Observable, concat, defer, finalize, from, interval, map, merge, switchMap } from 'rxjs';
import Redis from 'ioredis';
import { optionalLazyRedisOptions } from '../../common/redis/optional-lazy-redis-options';
import { loadFeatureFlags } from '../../config/feature-flags';
import { loadMapConfig } from '../../config/map.config';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { SiteEventsService } from '../../admin-realtime/services/site-events.service';
import { SiteEvent } from '../../admin-realtime/types/site-events.types';
import { ObservabilityStore } from '../../observability/observability.store';

/**
 * Public-stream privacy: REPORTED sites are visible only to their reporter, so
 * their coordinates must never be broadcast to every authenticated user.
 * Clients keep receiving the event as an invalidation hint (siteId + status);
 * without coordinates they fall back to a viewport refetch, which applies the
 * per-viewer visibility filter server-side.
 *
 * The admin dashboard uses the separate `/admin-realtime/events` stream and is
 * not affected.
 */
export function sanitizeSiteEventForPublicStream(event: SiteEvent): SiteEvent {
  if (event.mutation.status !== 'REPORTED') {
    return event;
  }
  if (event.mutation.latitude == null && event.mutation.longitude == null) {
    return event;
  }
  const { latitude: _latitude, longitude: _longitude, ...rest } = event.mutation;
  return { ...event, mutation: rest };
}

const cfg = loadMapConfig();
const flags = loadFeatureFlags();
const HEARTBEAT_INTERVAL_MS = cfg.sseHeartbeatIntervalMs;
const MAX_SSE_CONNECTIONS_PER_USER = 4;
const redis = cfg.redisUrl ? new Redis(cfg.redisUrl, optionalLazyRedisOptions) : null;
const USER_CONNECTION_KEY_PREFIX = 'map:sse:connections:user';
const USER_CONNECTION_KEY_TTL_SECONDS = Math.max(
  60,
  Math.ceil((HEARTBEAT_INTERVAL_MS * 3) / 1000),
);

async function openUserConnection(userId: string): Promise<void> {
  if (!redis) {
    return;
  }
  await redis.connect().catch(() => undefined);
  const key = `${USER_CONNECTION_KEY_PREFIX}:${userId}`;
  const nextCount = await redis.incr(key);
  if (nextCount === 1) {
    await redis.expire(key, USER_CONNECTION_KEY_TTL_SECONDS);
  }
  if (nextCount > MAX_SSE_CONNECTIONS_PER_USER) {
    await redis.decr(key);
    throw new HttpException(
      {
        code: 'MAP_SSE_CONNECTION_LIMIT',
        message: 'Too many active map realtime connections',
      },
      429,
    );
  }
  await redis.expire(key, USER_CONNECTION_KEY_TTL_SECONDS);
}

async function closeUserConnection(userId: string): Promise<void> {
  if (!redis) {
    return;
  }
  await redis.connect().catch(() => undefined);
  const key = `${USER_CONNECTION_KEY_PREFIX}:${userId}`;
  const nextCount = await redis.decr(key);
  if (nextCount <= 0) {
    await redis.del(key);
    return;
  }
  await redis.expire(key, USER_CONNECTION_KEY_TTL_SECONDS);
}

export function buildSiteEventsStream(
  siteEventsService: SiteEventsService,
  user: AuthenticatedUser | undefined,
  lastEventId?: string,
): Observable<NestMessageEvent> {
  if (!user) {
    throw new UnauthorizedException({
      code: 'UNAUTHORIZED',
      message: 'Authentication required',
    });
  }
  if (!flags.mapSseEnabled) {
    throw new HttpException({
      code: 'MAP_SSE_DISABLED',
      message: 'Server-Sent Events are temporarily disabled',
    }, 503);
  }
  return defer(() => {
    return from(openUserConnection(user.userId)).pipe(
      switchMap(() => {
        ObservabilityStore.recordMapSseConnected();
        const toSseEvent = (rawEvent: SiteEvent): NestMessageEvent => {
          ObservabilityStore.recordMapSseEventEmitted();
          const event = sanitizeSiteEventForPublicStream(rawEvent);
          return {
            data: event as object,
            type: event.type,
            id: event.eventId,
          };
        };
        const replay$ = from(siteEventsService.getReplaySince(lastEventId)).pipe(
          map((replayEvents) => {
            if (replayEvents.length > 0) {
              ObservabilityStore.recordMapSseReplayEvents(replayEvents.length);
            }
            return replayEvents;
          }),
          switchMap((events) => from(events)),
          map((event) => toSseEvent(event)),
        );
        const live$ = siteEventsService.getEvents().pipe(map((event) => toSseEvent(event)));
        const heartbeat$ = interval(HEARTBEAT_INTERVAL_MS).pipe(
          map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
        );
        return concat(replay$, merge(live$, heartbeat$)).pipe(
          finalize(() => {
            ObservabilityStore.recordMapSseDisconnected();
            void closeUserConnection(user.userId);
          }),
        );
      }),
    );
  });
}

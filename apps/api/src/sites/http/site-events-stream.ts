import {
  MessageEvent as NestMessageEvent,
  UnauthorizedException,
} from '@nestjs/common';
import { Observable, concat, defer, finalize, from, interval, map, merge } from 'rxjs';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { SiteEventsService } from '../../admin-events/site-events.service';
import { ObservabilityStore } from '../../observability/observability.store';

const HEARTBEAT_INTERVAL_MS = 30_000;

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
  return defer(() => {
    ObservabilityStore.recordMapSseConnected();
    const replayEvents = siteEventsService.getReplaySince(lastEventId);
    if (replayEvents.length > 0) {
      ObservabilityStore.recordMapSseReplayEvents(replayEvents.length);
    }
    const toSseEvent = (
      event: { eventId: string; type: string } & Record<string, unknown>,
    ): NestMessageEvent => {
      ObservabilityStore.recordMapSseEventEmitted();
      return {
        data: event as object,
        type: event.type,
        id: event.eventId,
      };
    };
    const replay$ = from(replayEvents).pipe(map((event) => toSseEvent(event)));
    const live$ = siteEventsService.getEvents().pipe(map((event) => toSseEvent(event)));
    const heartbeat$ = interval(HEARTBEAT_INTERVAL_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
    );
    return concat(replay$, merge(live$, heartbeat$)).pipe(
      finalize(() => {
        ObservabilityStore.recordMapSseDisconnected();
      }),
    );
  });
}

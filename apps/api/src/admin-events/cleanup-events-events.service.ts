import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type CleanupEventSseType = 'cleanup_event_created' | 'cleanup_event_updated' | 'cleanup_event_pending';

export type CleanupEventSsePayload = {
  type: CleanupEventSseType;
  eventId: string;
  moderationStatus?: string;
  lifecycleStatus?: string;
};

@Injectable()
export class CleanupEventsEventsService {
  private readonly events$ = new Subject<CleanupEventSsePayload>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitCleanupEventCreated(
    eventId: string,
    fields?: { moderationStatus?: string; lifecycleStatus?: string },
  ): void {
    const payload: CleanupEventSsePayload = { type: 'cleanup_event_created', eventId };
    if (fields?.moderationStatus !== undefined) {
      payload.moderationStatus = fields.moderationStatus;
    }
    if (fields?.lifecycleStatus !== undefined) {
      payload.lifecycleStatus = fields.lifecycleStatus;
    }
    this.events$.next(payload);
  }

  emitCleanupEventUpdated(
    eventId: string,
    fields?: { moderationStatus?: string; lifecycleStatus?: string },
  ): void {
    const payload: CleanupEventSsePayload = { type: 'cleanup_event_updated', eventId };
    if (fields?.moderationStatus !== undefined) {
      payload.moderationStatus = fields.moderationStatus;
    }
    if (fields?.lifecycleStatus !== undefined) {
      payload.lifecycleStatus = fields.lifecycleStatus;
    }
    this.events$.next(payload);
  }

  emitCleanupEventPending(eventId: string): void {
    this.events$.next({
      type: 'cleanup_event_pending',
      eventId,
      moderationStatus: 'PENDING',
    });
  }
}

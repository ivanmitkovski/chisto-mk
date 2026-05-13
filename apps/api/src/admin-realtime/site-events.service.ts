import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { EMPTY, Observable } from 'rxjs';
import { SiteEventOutboxDispatcherService } from './site-event-outbox-dispatcher.service';
import { SiteEventPublisherService } from './site-event-publisher.service';
import { SiteEventReplayStoreService } from './site-event-replay-store.service';
import { SiteEvent } from './site-events.types';

@Injectable()
export class SiteEventsService implements OnModuleDestroy, OnModuleInit {
  constructor(
    private readonly publisher: SiteEventPublisherService,
    private readonly outbox: SiteEventOutboxDispatcherService,
    private readonly replayStore: SiteEventReplayStoreService,
  ) {}

  onModuleInit(): void {
    this.outbox?.attachPublisher((event) => this.publisher.publish(event));
  }

  getEvents(): Observable<SiteEvent> {
    return this.publisher?.getEvents() ?? EMPTY;
  }

  async getReplaySince(lastEventId?: string): Promise<SiteEvent[]> {
    const normalized = lastEventId?.trim();
    if (!normalized) return [];
    const memoryReplay = this.publisher.getReplaySinceMemory(normalized);
    if (memoryReplay.length > 0) return memoryReplay;
    return this.replayStore.getReplaySinceFromDatabase(normalized);
  }

  async onModuleDestroy(): Promise<void> {
    await this.outbox?.onModuleDestroy();
    await this.publisher?.onModuleDestroy();
  }

  emitSiteCreated(
    siteId: string,
    details?: { status?: string; latitude?: number; longitude?: number; updatedAt?: Date },
  ): void {
    const now = details?.updatedAt ?? new Date();
    const event: SiteEvent = {
      eventId: `${siteId}:${now.getTime()}:site_created`,
      type: 'site_created',
      siteId,
      occurredAtMs: now.getTime(),
      updatedAt: now.toISOString(),
      mutation: {
        kind: 'created',
        ...(details?.status != null ? { status: details.status } : {}),
        ...(details?.latitude != null ? { latitude: details.latitude } : {}),
        ...(details?.longitude != null ? { longitude: details.longitude } : {}),
      },
    };
    void this.outbox?.enqueue(event);
    this.outbox?.kickNow();
  }

  emitSiteUpdated(
    siteId: string,
    details?: {
      status?: string;
      latitude?: number;
      longitude?: number;
      updatedAt?: Date;
      kind?: 'updated' | 'status_changed';
    },
  ): void {
    const now = details?.updatedAt ?? new Date();
    const event: SiteEvent = {
      eventId: `${siteId}:${now.getTime()}:site_updated`,
      type: 'site_updated',
      siteId,
      occurredAtMs: now.getTime(),
      updatedAt: now.toISOString(),
      mutation: {
        kind: details?.kind ?? 'updated',
        ...(details?.status != null ? { status: details.status } : {}),
        ...(details?.latitude != null ? { latitude: details.latitude } : {}),
        ...(details?.longitude != null ? { longitude: details.longitude } : {}),
      },
    };
    void this.outbox?.enqueue(event);
    this.outbox?.kickNow();
  }
}

import { Injectable } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';
import Redis, { type RedisOptions } from 'ioredis';
import { OwnerReportEvent } from '../reports-owner-events.types';

const REPORT_OWNER_EVENTS_CHANNEL = 'reports.owner.events';

export abstract class ReportEventBus {
  abstract publish(event: OwnerReportEvent): void;

  abstract subscribe(): Observable<OwnerReportEvent>;

  /** Best-effort teardown (Redis connections, subjects). */
  dispose(): void {
    // Default no-op.
  }
}

@Injectable()
export class InMemoryReportEventBus extends ReportEventBus {
  private readonly subject = new Subject<OwnerReportEvent>();

  publish(event: OwnerReportEvent): void {
    this.subject.next(event);
  }

  subscribe(): Observable<OwnerReportEvent> {
    return this.subject.asObservable();
  }

  override dispose(): void {
    this.subject.complete();
  }
}

@Injectable()
export class RedisReportEventBus extends ReportEventBus {
  private readonly publisher: Redis;

  private readonly subscriber: Redis;

  private readonly inbound = new Subject<OwnerReportEvent>();

  constructor(redisUrl: string) {
    super();
    const options: RedisOptions = { maxRetriesPerRequest: null, enableReadyCheck: true };
    this.publisher = new Redis(redisUrl, options);
    this.subscriber = new Redis(redisUrl, options);
    void this.subscriber.subscribe(REPORT_OWNER_EVENTS_CHANNEL).catch(() => undefined);
    this.subscriber.on('message', (channel: string, message: string) => {
      if (channel !== REPORT_OWNER_EVENTS_CHANNEL) {
        return;
      }
      try {
        const parsed = JSON.parse(message) as OwnerReportEvent;
        this.inbound.next(parsed);
      } catch {
        // Ignore malformed payloads.
      }
    });
  }

  publish(event: OwnerReportEvent): void {
    void this.publisher.publish(REPORT_OWNER_EVENTS_CHANNEL, JSON.stringify(event));
  }

  subscribe(): Observable<OwnerReportEvent> {
    return this.inbound.asObservable();
  }

  override dispose(): void {
    void this.subscriber.quit();
    void this.publisher.quit();
    this.inbound.complete();
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';
import Redis, { type RedisOptions } from 'ioredis';
import { OwnerReportEvent } from '../types/reports-owner-events.types';

const REPORT_OWNER_EVENTS_CHANNEL = 'reports.owner.events';

function whenRedisReady(client: Redis): Promise<void> {
  if (client.status === 'ready') {
    return Promise.resolve();
  }
  return new Promise<void>((resolve, reject) => {
    client.once('ready', resolve);
    client.once('error', reject);
  });
}

export abstract class ReportEventBus {
  abstract publish(event: OwnerReportEvent): void;

  abstract subscribe(): Observable<OwnerReportEvent>;

  /** Resolves when the bus can reliably publish/receive (immediate for in-memory). */
  whenReady(): Promise<void> {
    return Promise.resolve();
  }

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
  private readonly logger = new Logger(RedisReportEventBus.name);

  private readonly publisher: Redis;

  private readonly subscriber: Redis;

  private readonly inbound = new Subject<OwnerReportEvent>();

  private readonly ready: Promise<void>;

  constructor(redisUrl: string) {
    super();
    const options: RedisOptions = { maxRetriesPerRequest: null, enableReadyCheck: true };
    this.publisher = new Redis(redisUrl, options);
    this.subscriber = new Redis(redisUrl, options);
    this.subscriber.on('message', (channel: string, message: string) => {
      if (channel !== REPORT_OWNER_EVENTS_CHANNEL) {
        return;
      }
      try {
        const parsed = JSON.parse(message) as OwnerReportEvent;
        this.inbound.next(parsed);
      } catch (err: unknown) {
        this.logger.warn(
          `report owner events malformed payload: ${err instanceof Error ? err.message : String(err)}`,
        );
      }
    });
    this.ready = Promise.all([whenRedisReady(this.publisher), whenRedisReady(this.subscriber)])
      .then(() => this.subscriber.subscribe(REPORT_OWNER_EVENTS_CHANNEL))
      .then(() => undefined)
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : String(err);
        this.logger.warn(`report owner events subscribe failed: ${message}`);
        throw err;
      });
  }

  override whenReady(): Promise<void> {
    return this.ready;
  }

  publish(event: OwnerReportEvent): void {
    void this.ready.then(() => {
      void this.publisher.publish(REPORT_OWNER_EVENTS_CHANNEL, JSON.stringify(event)).catch((err: unknown) => {
        this.logger.warn(
          `report owner events publish failed: ${err instanceof Error ? err.message : String(err)}`,
        );
      });
    });
  }

  subscribe(): Observable<OwnerReportEvent> {
    return this.inbound.asObservable();
  }

  override dispose(): void {
    this.inbound.complete();
    void this.ready.finally(() => {
      void this.subscriber.quit();
      void this.publisher.quit();
    });
  }
}

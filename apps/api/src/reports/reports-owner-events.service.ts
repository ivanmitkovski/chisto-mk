import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Observable, filter } from 'rxjs';
import { OwnerReportEvent, OwnerReportEventMutation, OwnerReportEventType } from './reports-owner-events.types';
import { ReportEventBus } from './owner-events/report-event-bus';

@Injectable()
export class ReportsOwnerEventsService implements OnModuleDestroy {
  constructor(private readonly bus: ReportEventBus) {}

  onModuleDestroy(): void {
    this.bus.dispose();
  }

  getEventsForOwner(ownerId: string): Observable<OwnerReportEvent> {
    return this.bus.subscribe().pipe(filter((e) => e.ownerId === ownerId));
  }

  emit(ownerId: string, reportId: string, type: OwnerReportEventType, mutation: OwnerReportEventMutation): void {
    const event: OwnerReportEvent = {
      eventId: randomUUID(),
      type,
      ownerId,
      reportId,
      occurredAtMs: Date.now(),
      mutation,
    };
    this.bus.publish(event);
  }

  /** Primary reporter and all co-reporters receive the same event (deduped by user id). */
  emitToReportInterestedParties(
    reportId: string,
    reporterId: string | null,
    coReporterUserIds: readonly string[],
    type: OwnerReportEventType,
    mutation: OwnerReportEventMutation,
  ): void {
    const recipients = new Set<string>();
    if (reporterId) {
      recipients.add(reporterId);
    }
    for (const id of coReporterUserIds) {
      if (id) {
        recipients.add(id);
      }
    }
    for (const ownerId of recipients) {
      this.emit(ownerId, reportId, type, mutation);
    }
  }
}

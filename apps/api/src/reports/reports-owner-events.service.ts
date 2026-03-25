import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Observable, Subject, filter } from 'rxjs';
import { OwnerReportEvent, OwnerReportEventMutation, OwnerReportEventType } from './reports-owner-events.types';

@Injectable()
export class ReportsOwnerEventsService {
  private readonly events$ = new Subject<OwnerReportEvent>();

  getEventsForOwner(ownerId: string): Observable<OwnerReportEvent> {
    return this.events$.asObservable().pipe(filter((e) => e.ownerId === ownerId));
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
    this.events$.next(event);
  }
}


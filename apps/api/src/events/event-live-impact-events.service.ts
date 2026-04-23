import { Injectable } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';
import { filter } from 'rxjs/operators';

export interface LiveImpactBroadcast {
  eventId: string;
}

/**
 * Fan-out hook for per-event live impact (SSE + optional WS) without tight coupling to HTTP.
 */
@Injectable()
export class EventLiveImpactEventsService {
  private readonly subject = new Subject<LiveImpactBroadcast>();

  emitChanged(eventId: string): void {
    this.subject.next({ eventId });
  }

  watchEvent(eventId: string): Observable<LiveImpactBroadcast> {
    return this.subject.pipe(filter((e) => e.eventId === eventId));
  }

  /** For diagnostics / tests */
  asObservable(): Observable<LiveImpactBroadcast> {
    return this.subject.asObservable();
  }
}

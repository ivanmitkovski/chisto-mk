import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type ReportEventType = 'report_created' | 'report_updated';

export type ReportEvent = {
  type: ReportEventType;
  reportId: string;
};

@Injectable()
export class ReportEventsService {
  private readonly events$ = new Subject<ReportEvent>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitReportCreated(reportId: string): void {
    this.events$.next({ type: 'report_created', reportId });
  }

  emitReportStatusUpdated(reportId: string): void {
    this.events$.next({ type: 'report_updated', reportId });
  }
}

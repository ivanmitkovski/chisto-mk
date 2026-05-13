import { Injectable } from '@nestjs/common';

import { AdminTopicEventBus } from './admin-topic-event-bus';

export type ReportEventType = 'report_created' | 'report_updated';

export type ReportEvent = {
  type: ReportEventType;
  reportId: string;
};

@Injectable()
export class ReportEventsService {
  private readonly bus = new AdminTopicEventBus<ReportEvent>();

  getEvents() {
    return this.bus.getEvents();
  }

  emitReportCreated(reportId: string): void {
    this.bus.emit({ type: 'report_created', reportId });
  }

  emitReportStatusUpdated(reportId: string): void {
    this.bus.emit({ type: 'report_updated', reportId });
  }
}

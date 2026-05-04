import { Module } from '@nestjs/common';
import { ReportsOwnerEventsService } from '../reports-owner-events.service';
import { InMemoryReportEventBus, RedisReportEventBus, ReportEventBus } from './report-event-bus';

@Module({
  providers: [
    {
      provide: ReportEventBus,
      useFactory: (): ReportEventBus => {
        const url = process.env.REDIS_URL?.trim();
        if (url) {
          return new RedisReportEventBus(url);
        }
        return new InMemoryReportEventBus();
      },
    },
    ReportsOwnerEventsService,
  ],
  exports: [ReportsOwnerEventsService],
})
export class OwnerEventsModule {}

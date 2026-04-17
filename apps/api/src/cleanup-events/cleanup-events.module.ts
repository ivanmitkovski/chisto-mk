import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { GamificationModule } from '../gamification/gamification.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CleanupEventsController } from './cleanup-events.controller';
import { CleanupEventsService } from './cleanup-events.service';

@Module({
  imports: [
    AdminEventsModule,
    AuditModule,
    EventScheduleConflictModule,
    GamificationModule,
    ReportsUploadModule,
  ],
  controllers: [CleanupEventsController],
  providers: [CleanupEventsService],
})
export class CleanupEventsModule {}

import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminEventsController } from './admin-events.controller';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventsService } from './site-events.service';
import { UserCreatedListener } from './user-created.listener';
import { UserEventsService } from './user-events.service';
import { CleanupEventsEventsService } from './cleanup-events-events.service';

@Module({
  imports: [AuthModule],
  controllers: [AdminEventsController],
  providers: [
    UserCreatedListener,
    ReportEventsService,
    NotificationEventsService,
    SiteEventsService,
    UserEventsService,
    CleanupEventsEventsService,
  ],
  exports: [
    ReportEventsService,
    NotificationEventsService,
    SiteEventsService,
    UserEventsService,
    CleanupEventsEventsService,
  ],
})
export class AdminEventsModule {}

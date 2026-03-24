import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminEventsController } from './admin-events.controller';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventsService } from './site-events.service';
import { UserCreatedListener } from './user-created.listener';
import { UserEventsService } from './user-events.service';

@Module({
  imports: [AuthModule],
  controllers: [AdminEventsController],
  providers: [
    UserCreatedListener,
    ReportEventsService,
    NotificationEventsService,
    SiteEventsService,
    UserEventsService,
  ],
  exports: [
    ReportEventsService,
    NotificationEventsService,
    SiteEventsService,
    UserEventsService,
  ],
})
export class AdminEventsModule {}

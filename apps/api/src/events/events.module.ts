import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { EventChatModule } from '../event-chat/event-chat.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { EventCheckInGateway } from './event-check-in.gateway';
import { EventsCheckInController } from './events-check-in.controller';
import { EventsCheckInService } from './events-check-in.service';
import { EventsController } from './events.controller';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsService } from './events.service';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventsTelemetryService } from './events-telemetry.service';
import { EventsCheckInThrottlerGuard } from './events-check-in-throttler.guard';
import { EventEndSoonNotifierService } from './event-end-soon-notifier.service';

@Module({
  imports: [
    PrismaModule,
    EventScheduleConflictModule,
    ReportsUploadModule,
    GamificationModule,
    NotificationsModule,
    EventChatModule,
    AdminEventsModule,
  ],
  controllers: [EventsController, EventsCheckInController],
  providers: [
    EventsMobileMapperService,
    EventsTelemetryService,
    EventsService,
    CheckInTelemetryService,
    EventsCheckInService,
    EventCheckInGateway,
    PendingCheckInService,
    EventsCheckInThrottlerGuard,
    EventEndSoonNotifierService,
  ],
  exports: [EventsService],
})
export class EventsModule {}

import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { EventChatModule } from '../event-chat/event-chat.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CheckInRepository } from './check-in.repository';
import { EventCheckInGateway } from './event-check-in.gateway';
import { EventEvidenceService } from './event-evidence.service';
import { EventsCleanupMediaUploadService } from './events-cleanup-media-upload.service';
import { EventLiveImpactEventsService } from './event-live-impact-events.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { EventsFieldBatchService } from './events-field-batch.service';
import { EventsCheckInController } from './events-check-in.controller';
import { EventsCheckInAttendeesService } from './events-check-in-attendees.service';
import { EventsCheckInQrService } from './events-check-in-qr.service';
import { EventsCheckInRedemptionService } from './events-check-in-redemption.service';
import { EventsCheckInService } from './events-check-in.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { EventsController } from './events.controller';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsCreationService } from './events-creation.service';
import { EventsLifecycleParticipationService } from './events-lifecycle-participation.service';
import { EventsQueryService } from './events-query.service';
import { EventsRepository } from './events.repository';
import { EventsService } from './events.service';
import { EventsUpdateService } from './events-update.service';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventsTelemetryService } from './events-telemetry.service';
import { EventsCheckInThrottlerGuard } from './events-check-in-throttler.guard';
import { EventEndSoonNotifierService } from './event-end-soon-notifier.service';
import { EventImpactReceiptService } from './event-impact-receipt.service';

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
    EventsRepository,
    EventsMobileMapperService,
    EventsTelemetryService,
    EventsQueryService,
    EventsCreationService,
    EventsUpdateService,
    EventsLifecycleParticipationService,
    EventsService,
    CheckInTelemetryService,
    CheckInRepository,
    EventsCheckInSharedService,
    EventsCheckInQrService,
    EventsCheckInAttendeesService,
    EventsCheckInRedemptionService,
    EventsCheckInService,
    EventLiveImpactEventsService,
    EventLiveImpactService,
    EventEvidenceService,
    EventsCleanupMediaUploadService,
    EventRouteSegmentsService,
    EventsFieldBatchService,
    EventCheckInGateway,
    PendingCheckInService,
    EventsCheckInThrottlerGuard,
    EventEndSoonNotifierService,
    EventImpactReceiptService,
  ],
  exports: [EventsService],
})
export class EventsModule {}

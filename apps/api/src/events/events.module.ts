import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { EventChatModule } from '../event-chat/event-chat.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CheckInRepository } from './check-in.repository';
import { EventCheckInGateway } from './event-check-in.gateway';
import { EventCheckInRoomEmitterService } from './event-check-in-room-emitter.service';
import { EventEvidenceService } from './event-evidence.service';
import { EventsCleanupMediaUploadService } from './events-cleanup-media-upload.service';
import { EventLiveImpactEventsService } from './event-live-impact-events.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { EventsFieldBatchService } from './events-field-batch.service';
import { EventsCheckInController } from './events-check-in.controller';
import { EventsCheckInAttendeesService } from './events-check-in-attendees.service';
import { EventsCheckInQrService } from './events-check-in-qr.service';
import { EventsCheckInRedeemService } from './events-check-in-redeem.service';
import { EventsCheckInResolveService } from './events-check-in-resolve.service';
import { EventsCheckInRedemptionService } from './events-check-in-redemption.service';
import { EventsCheckInService } from './events-check-in.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { EventsController } from './events.controller';
import { EventsListController } from './events-list.controller';
import { EventsEvidenceController } from './events-evidence.controller';
import { EventsLiveImpactController } from './events-live-impact.controller';
import { EventsRouteController } from './events-route.controller';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsAfterImagesService } from './events-after-images.service';
import { EventsAnalyticsService } from './events-analytics.service';
import { EventCreationPersistenceService } from './event-creation-persistence.service';
import { EventCreationValidationService } from './event-creation-validation.service';
import { EventUpdateValidationService } from './event-update-validation.service';
import { EventsCreationService } from './events-creation.service';
import { EventsLifecycleService } from './events-lifecycle.service';
import { EventsParticipationService } from './events-participation.service';
import { EventsDetailQueryService } from './events-detail-query.service';
import { EventsListQueryService } from './events-list-query.service';
import { EventsQueryService } from './events-query.service';
import { EventsScheduleConflictPreviewQueryService } from './events-schedule-conflict-preview-query.service';
import { EventsShareCardQueryService } from './events-share-card-query.service';
import { EventsSearchQueryService } from './events-search-query.service';
import { EventsSearchService } from './events-search.service';
import { EventsRepository } from './events.repository';
import { EventsUpdateService } from './events-update.service';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventsTelemetryService } from './events-telemetry.service';
import { EventsCheckInThrottlerGuard } from './events-check-in-throttler.guard';
import { EventEndSoonNotifierService } from './event-end-soon-notifier.service';
import { EventImpactReceiptService } from './event-impact-receipt.service';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    EventScheduleConflictModule,
    ReportsUploadModule,
    GamificationModule,
    NotificationsModule,
    EventChatModule,
    AdminRealtimeModule,
  ],
  controllers: [
    EventsListController,
    EventsEvidenceController,
    EventsRouteController,
    EventsLiveImpactController,
    EventsController,
    EventsCheckInController,
  ],
  providers: [
    EventsRepository,
    EventsMobileMapperService,
    EventsTelemetryService,
    EventsSearchQueryService,
    EventsSearchService,
    EventsShareCardQueryService,
    EventsScheduleConflictPreviewQueryService,
    EventsListQueryService,
    EventsDetailQueryService,
    EventsQueryService,
    EventCreationValidationService,
    EventCreationPersistenceService,
    EventsCreationService,
    EventUpdateValidationService,
    EventsUpdateService,
    EventsLifecycleService,
    EventsParticipationService,
    EventsAfterImagesService,
    EventsAnalyticsService,
    CheckInTelemetryService,
    CheckInRepository,
    EventsCheckInSharedService,
    EventsCheckInQrService,
    EventsCheckInAttendeesService,
    EventsCheckInRedeemService,
    EventsCheckInResolveService,
    EventsCheckInRedemptionService,
    EventsCheckInService,
    EventLiveImpactEventsService,
    EventCheckInRoomEmitterService,
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
})
export class EventsModule {}

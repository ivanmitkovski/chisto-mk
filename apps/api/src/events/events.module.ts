import { Module, forwardRef } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { EventChatModule } from '../event-chat/event-chat.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CheckInRepository } from './repositories/check-in.repository';
import { EventCheckInGateway } from './gateways/event-check-in.gateway';
import { EventCheckInRoomEmitterService } from './services/event-check-in-room-emitter.service';
import { EventEvidenceService } from './services/event-evidence.service';
import { EventsCleanupMediaUploadService } from './services/events-cleanup-media-upload.service';
import { EventLiveImpactEventsService } from './services/event-live-impact-events.service';
import { EventLiveImpactService } from './services/event-live-impact.service';
import { EventRouteSegmentsService } from './services/event-route-segments.service';
import { EventsFieldBatchService } from './services/events-field-batch.service';
import { EventsCheckInController } from './controllers/events-check-in.controller';
import { EventsCheckInAttendeesService } from './services/events-check-in-attendees.service';
import { EventsCheckInQrService } from './services/events-check-in-qr.service';
import { EventsCheckInRedeemService } from './services/events-check-in-redeem.service';
import { EventsCheckInResolveService } from './services/events-check-in-resolve.service';
import { EventsCheckInRedemptionService } from './services/events-check-in-redemption.service';
import { EventsCheckInService } from './services/events-check-in.service';
import { EventsCheckInSharedService } from './services/events-check-in-shared.service';
import { EventsController } from './controllers/events.controller';
import { EventsListController } from './controllers/events-list.controller';
import { EventsEvidenceController } from './controllers/events-evidence.controller';
import { EventsLiveImpactController } from './controllers/events-live-impact.controller';
import { EventsRouteController } from './controllers/events-route.controller';
import { EventsMobileMapperService } from './services/events-mobile-mapper.service';
import { EventsAfterImagesService } from './services/events-after-images.service';
import { EventsAnalyticsService } from './services/events-analytics.service';
import { EventCreationPersistenceService } from './services/event-creation-persistence.service';
import { EventCreationValidationService } from './services/event-creation-validation.service';
import { EventUpdateValidationService } from './services/event-update-validation.service';
import { EventsCreationService } from './services/events-creation.service';
import { EventsLifecycleService } from './services/events-lifecycle.service';
import { EventsParticipationService } from './services/events-participation.service';
import { EventsDetailQueryService } from './services/events-detail-query.service';
import { EventsListQueryService } from './services/events-list-query.service';
import { EventsQueryService } from './services/events-query.service';
import { EventsScheduleConflictPreviewQueryService } from './services/events-schedule-conflict-preview-query.service';
import { EventsShareCardQueryService } from './services/events-share-card-query.service';
import { EventsSearchQueryService } from './services/events-search-query.service';
import { EventsSearchService } from './services/events-search.service';
import { EventsRepository } from './repositories/events.repository';
import { EventsUpdateService } from './services/events-update.service';
import { PendingCheckInService } from './services/pending-check-in.service';
import { CheckInTelemetryService } from './services/check-in-telemetry.service';
import { EventsTelemetryService } from './services/events-telemetry.service';
import { EventsCheckInThrottlerGuard } from './guards/events-check-in-throttler.guard';
import { EventEndSoonNotifierService } from './services/event-end-soon-notifier.service';
import { EventImpactReceiptService } from './services/event-impact-receipt.service';
import { SitesModule } from '../sites/sites.module';

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
    forwardRef(() => SitesModule),
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

import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminRealtimeController } from './controllers/admin-realtime.controller';
import { CleanupEventRealtimeService } from './services/cleanup-event-realtime.service';
import { NotificationEventsService } from './services/notification-events.service';
import { ReportEventsService } from './services/report-events.service';
import { SiteEventOutboxDispatcherService } from './services/site-event-outbox-dispatcher.service';
import { SiteEventPublisherService } from './services/site-event-publisher.service';
import { SiteEventReplayStoreService } from './services/site-event-replay-store.service';
import { SiteEventsService } from './services/site-events.service';
import { UserCreatedListener } from './listeners/user-created.listener';
import { UserEventsService } from './services/user-events.service';
import { MapCdnPurgeService } from '../observability/services/map-cdn-purge.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [AdminRealtimeController],
  providers: [
    MapCdnPurgeService,
    UserCreatedListener,
    ReportEventsService,
    NotificationEventsService,
    SiteEventOutboxDispatcherService,
    SiteEventPublisherService,
    SiteEventReplayStoreService,
    SiteEventsService,
    UserEventsService,
    CleanupEventRealtimeService,
  ],
  exports: [
    ReportEventsService,
    NotificationEventsService,
    SiteEventsService,
    UserEventsService,
    CleanupEventRealtimeService,
  ],
})
export class AdminRealtimeModule {}

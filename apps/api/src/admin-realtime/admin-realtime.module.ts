import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminRealtimeController } from './admin-realtime.controller';
import { CleanupEventRealtimeService } from './cleanup-event-realtime.service';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventOutboxDispatcherService } from './site-event-outbox-dispatcher.service';
import { SiteEventPublisherService } from './site-event-publisher.service';
import { SiteEventReplayStoreService } from './site-event-replay-store.service';
import { SiteEventsService } from './site-events.service';
import { UserCreatedListener } from './user-created.listener';
import { UserEventsService } from './user-events.service';
import { MapCdnPurgeService } from '../observability/map-cdn-purge.service';

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

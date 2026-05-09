import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminEventsController } from './admin-events.controller';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventsService } from './site-events.service';
import { UserCreatedListener } from './user-created.listener';
import { UserEventsService } from './user-events.service';
import { CleanupEventsEventsService } from './cleanup-events-events.service';
import { SiteEventOutboxDispatcherService } from './site-event-outbox-dispatcher.service';
import { SiteEventPublisherService } from './site-event-publisher.service';
import { SiteEventReplayStoreService } from './site-event-replay-store.service';
import { MapCdnPurgeService } from '../observability/map-cdn-purge.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [AdminEventsController],
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

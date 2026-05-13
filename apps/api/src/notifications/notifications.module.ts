import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsController } from './notifications.controller';
import { NotificationInboxService } from './notification-inbox.service';
import { NotificationStateService } from './notification-state.service';
import { NotificationPreferencesService } from './notification-preferences.service';
import { NotificationWriterService } from './notification-writer.service';
import { DeviceTokenService } from './device-token.service';
import { FcmPushService } from './fcm-push.service';
import { PushDeliveryWorkerService } from './push-delivery-worker.service';
import { NotificationDispatcherService } from './notification-dispatcher.service';
import { CleanupEventNotificationsService } from './cleanup-event-notifications.service';

@Module({
  imports: [PrismaModule, ConfigModule, FeatureFlagsModule],
  controllers: [NotificationsController],
  providers: [
    NotificationInboxService,
    NotificationStateService,
    NotificationPreferencesService,
    NotificationWriterService,
    DeviceTokenService,
    FcmPushService,
    PushDeliveryWorkerService,
    NotificationDispatcherService,
    CleanupEventNotificationsService,
  ],
  exports: [
    NotificationDispatcherService,
    CleanupEventNotificationsService,
    NotificationWriterService,
    DeviceTokenService,
    NotificationInboxService,
    NotificationStateService,
    NotificationPreferencesService,
  ],
})
export class NotificationsModule {}

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailModule } from '../email/email.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { NotificationsController } from './notifications.controller';
import { NotificationInboxService } from './notification-inbox.service';
import { NotificationStateService } from './notification-state.service';
import { NotificationPreferencesService } from './notification-preferences.service';
import { NotificationWriterService } from './notification-writer.service';
import { DeviceTokenService } from './device-token.service';
import { FcmPushService } from './fcm-push.service';
import { PushDeliveryWorkerService } from './push-delivery-worker.service';
import { PushDeliveryOutboxService } from './push-delivery-outbox.service';
import { PushDeliverySenderService } from './push-delivery-sender.service';
import { NotificationDispatcherService } from './notification-dispatcher.service';
import { CleanupEventNotificationsService } from './cleanup-event-notifications.service';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsRoomEmitterService } from './notifications-room-emitter.service';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    FeatureFlagsModule,
    EmailModule,
    ReportsUploadModule,
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationInboxService,
    NotificationStateService,
    NotificationPreferencesService,
    NotificationWriterService,
    DeviceTokenService,
    FcmPushService,
    PushDeliveryOutboxService,
    PushDeliverySenderService,
    PushDeliveryWorkerService,
    NotificationDispatcherService,
    CleanupEventNotificationsService,
    NotificationsRoomEmitterService,
    NotificationsGateway,
  ],
  exports: [
    NotificationDispatcherService,
    CleanupEventNotificationsService,
    NotificationWriterService,
    DeviceTokenService,
    NotificationInboxService,
    NotificationStateService,
    NotificationPreferencesService,
    NotificationsRoomEmitterService,
  ],
})
export class NotificationsModule {}

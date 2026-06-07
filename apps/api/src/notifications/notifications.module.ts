import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailModule } from '../email/email.module';
import { AdminModerationEmailModule } from '../admin-moderation-email/admin-moderation-email.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { NotificationsInboxController } from './controllers/notifications-inbox.controller';
import { NotificationsStateController } from './controllers/notifications-state.controller';
import { NotificationsAdminController } from './controllers/notifications-admin.controller';
import { NotificationInboxService } from './services/notification-inbox.service';
import { NotificationInboxActorsService } from './services/notification-inbox-actors.service';
import { NotificationInboxAdminService } from './services/notification-inbox-admin.service';
import { NotificationStateService } from './services/notification-state.service';
import { NotificationPreferencesService } from './services/notification-preferences.service';
import { NotificationWriterService } from './services/notification-writer.service';
import { DeviceTokenService } from './services/device-token.service';
import { FcmPushService } from './services/fcm-push.service';
import { PushDeliveryWorkerService } from './services/push-delivery-worker.service';
import { PushDeliveryOutboxService } from './services/push-delivery-outbox.service';
import { PushDeliverySenderService } from './services/push-delivery-sender.service';
import { NotificationDispatcherService } from './services/notification-dispatcher.service';
import { CleanupEventNotificationsService } from './services/cleanup-event-notifications.service';
import { NotificationsGateway } from './gateways/notifications.gateway';
import { NotificationsRoomEmitterService } from './services/notifications-room-emitter.service';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    FeatureFlagsModule,
    EmailModule,
    AdminModerationEmailModule,
    ReportsUploadModule,
  ],
  controllers: [
    NotificationsInboxController,
    NotificationsStateController,
    NotificationsAdminController,
  ],
  providers: [
    NotificationInboxService,
    NotificationInboxActorsService,
    NotificationInboxAdminService,
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

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailModule } from '../email/email.module';
import { AdminModerationEmailModule } from '../admin-moderation-email/admin-moderation-email.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { AuditModule } from '../audit/audit.module';
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
import { PushDeadLetterRequeueService } from './services/push-dead-letter-requeue.service';
import { PushDiagnosticsService } from './services/push-diagnostics.service';
import { PushPipelineHealthService } from './services/push-pipeline-health.service';
import { NotificationDispatcherService } from './services/notification-dispatcher.service';
import { CleanupEventNotificationsService } from './services/cleanup-event-notifications.service';
import { NearbyUsersForReportService } from './services/nearby-users-for-report.service';
import { NearbyReportNotificationService } from './services/nearby-report-notification.service';
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
    AuditModule,
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
    PushDeadLetterRequeueService,
    PushDiagnosticsService,
    PushPipelineHealthService,
    PushDeliveryWorkerService,
    NotificationDispatcherService,
    CleanupEventNotificationsService,
    NearbyUsersForReportService,
    NearbyReportNotificationService,
    NotificationsRoomEmitterService,
    NotificationsGateway,
  ],
  exports: [
    NotificationDispatcherService,
    CleanupEventNotificationsService,
    NearbyReportNotificationService,
    NotificationWriterService,
    DeviceTokenService,
    FcmPushService,
    NotificationInboxService,
    NotificationStateService,
    NotificationPreferencesService,
    NotificationsRoomEmitterService,
    PushPipelineHealthService,
    PushDiagnosticsService,
  ],
})
export class NotificationsModule {}

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { FcmPushService } from './fcm-push.service';
import { PushDeliveryWorkerService } from './push-delivery-worker.service';
import { NotificationDispatcherService } from './notification-dispatcher.service';
import { CleanupEventNotificationsService } from './cleanup-event-notifications.service';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    FcmPushService,
    PushDeliveryWorkerService,
    NotificationDispatcherService,
    CleanupEventNotificationsService,
  ],
  exports: [NotificationsService, NotificationDispatcherService, CleanupEventNotificationsService],
})
export class NotificationsModule {}

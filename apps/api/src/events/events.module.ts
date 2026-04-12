import { Module } from '@nestjs/common';
import { EventChatModule } from '../event-chat/event-chat.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { EventsCheckInController } from './events-check-in.controller';
import { EventsCheckInService } from './events-check-in.service';
import { EventsController } from './events.controller';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsService } from './events.service';

@Module({
  imports: [
    PrismaModule,
    ReportsUploadModule,
    GamificationModule,
    NotificationsModule,
    EventChatModule,
  ],
  controllers: [EventsController, EventsCheckInController],
  providers: [EventsMobileMapperService, EventsService, EventsCheckInService],
  exports: [EventsService],
})
export class EventsModule {}

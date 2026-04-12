import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { ChatEncryptionService } from './chat-encryption.service';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { EventChatAccessService } from './event-chat-access.service';
import { EventChatController } from './event-chat.controller';
import { EventChatGateway } from './event-chat.gateway';
import { EventChatService } from './event-chat.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatUploadService } from './event-chat-upload.service';
import { EventChatClusterConfig } from './event-chat-cluster.config';

@Module({
  imports: [PrismaModule, NotificationsModule, ReportsUploadModule],
  controllers: [EventChatController],
  providers: [
    EventChatClusterConfig,
    EventChatService,
    EventChatSseService,
    EventChatGateway,
    EventChatUploadService,
    ChatEncryptionService,
    EventChatAccessService,
    EventChatAccessGuard,
  ],
  exports: [
    EventChatClusterConfig,
    EventChatService,
    EventChatSseService,
    EventChatGateway,
    ChatEncryptionService,
  ],
})
export class EventChatModule {}

import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { ChatEncryptionService } from './chat-encryption.service';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { EventChatAccessService } from './event-chat-access.service';
import { EventChatController } from './event-chat.controller';
import { EventChatGateway } from './event-chat.gateway';
import { EventChatListService } from './event-chat-list.service';
import { EventChatMessageDtoService } from './event-chat-message-dto.service';
import { EventChatMutationsService } from './event-chat-mutations.service';
import { EventChatNotificationsService } from './event-chat-notifications.service';
import { EventChatPresenceService } from './event-chat-presence.service';
import { EventChatService } from './event-chat.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatUploadService } from './event-chat-upload.service';
import { EventChatClusterConfig } from './event-chat-cluster.config';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatThrottlerGuard } from './event-chat-throttler.guard';

@Module({
  imports: [PrismaModule, NotificationsModule, ReportsUploadModule],
  controllers: [EventChatController],
  providers: [
    EventChatClusterConfig,
    EventChatTelemetryService,
    EventChatThrottlerGuard,
    EventChatNotificationsService,
    EventChatMessageDtoService,
    EventChatListService,
    EventChatPresenceService,
    EventChatMutationsService,
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

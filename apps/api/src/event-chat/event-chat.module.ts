import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { ChatEncryptionService } from './chat-encryption.service';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { EventChatAccessService } from './event-chat-access.service';
import { EventChatReadController } from './event-chat-read.controller';
import { EventChatMessagesController } from './event-chat-messages.controller';
import { EventChatGateway } from './event-chat.gateway';
import { EventChatRoomEmitterService } from './event-chat-room-emitter.service';
import { EventChatListService } from './event-chat-list.service';
import { EventChatMessageDtoService } from './event-chat-message-dto.service';
import { EventChatMutationModerateService } from './event-chat-mutation-moderate.service';
import { EventChatMutationSendService } from './event-chat-mutation-send.service';
import { EventChatMutationsService } from './event-chat-mutations.service';
import { EventChatNotificationsService } from './event-chat-notifications.service';
import { EventChatPresenceMuteService } from './event-chat-presence-mute.service';
import { EventChatPresenceReadStateService } from './event-chat-presence-read-state.service';
import { EventChatPresenceRosterService } from './event-chat-presence-roster.service';
import { EventChatPresenceTypingService } from './event-chat-presence-typing.service';
import { EventChatPresenceService } from './event-chat-presence.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatUploadService } from './event-chat-upload.service';
import { EventChatClusterConfig } from './event-chat-cluster.config';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatThrottlerGuard } from './event-chat-throttler.guard';

@Module({
  imports: [ConfigModule, PrismaModule, NotificationsModule, ReportsUploadModule],
  controllers: [EventChatReadController, EventChatMessagesController],
  providers: [
    EventChatClusterConfig,
    EventChatTelemetryService,
    EventChatThrottlerGuard,
    EventChatNotificationsService,
    EventChatMessageDtoService,
    EventChatListService,
    EventChatPresenceMuteService,
    EventChatPresenceRosterService,
    EventChatPresenceReadStateService,
    EventChatPresenceTypingService,
    EventChatPresenceService,
    EventChatMutationSendService,
    EventChatMutationModerateService,
    EventChatMutationsService,
    EventChatSseService,
    EventChatRoomEmitterService,
    EventChatGateway,
    EventChatUploadService,
    ChatEncryptionService,
    EventChatAccessService,
    EventChatAccessGuard,
  ],
  exports: [
    EventChatClusterConfig,
    EventChatMutationsService,
    EventChatSseService,
    EventChatGateway,
    ChatEncryptionService,
  ],
})
export class EventChatModule {}

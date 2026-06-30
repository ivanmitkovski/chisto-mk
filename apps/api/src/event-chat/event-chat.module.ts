import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ModerationModule } from '../moderation/moderation.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { ChatEncryptionService } from './services/chat-encryption.service';
import { EventChatAccessGuard } from './guards/event-chat-access.guard';
import { EventChatAccessService } from './services/event-chat-access.service';
import { EventChatReadController } from './controllers/event-chat-read.controller';
import { EventChatMessagesController } from './controllers/event-chat-messages.controller';
import { EventChatGateway } from './gateways/event-chat.gateway';
import { EventChatRoomEmitterService } from './services/event-chat-room-emitter.service';
import { EventChatListService } from './services/event-chat-list.service';
import { EventChatMessageDtoService } from './services/event-chat-message-dto.service';
import { EventChatMutationModerateService } from './services/event-chat-mutation-moderate.service';
import { EventChatMutationSendService } from './services/event-chat-mutation-send.service';
import { EventChatMutationsService } from './services/event-chat-mutations.service';
import { EventChatNotificationsService } from './services/event-chat-notifications.service';
import { EventChatPushAggregatorService } from './services/event-chat-push-aggregator.service';
import { EventChatPresenceMuteService } from './services/event-chat-presence-mute.service';
import { EventChatPresenceReadStateService } from './services/event-chat-presence-read-state.service';
import { EventChatPresenceRosterService } from './services/event-chat-presence-roster.service';
import { EventChatPresenceTypingService } from './services/event-chat-presence-typing.service';
import { EventChatPresenceService } from './services/event-chat-presence.service';
import { EventChatSseService } from './services/event-chat-sse.service';
import { EventChatUploadService } from './services/event-chat-upload.service';
import { EventChatClusterConfig } from './constants/event-chat-cluster.config';
import { EventChatTelemetryService } from './services/event-chat-telemetry.service';
import { EventChatThrottlerGuard } from './guards/event-chat-throttler.guard';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    ModerationModule,
    FeatureFlagsModule,
    NotificationsModule,
    ReportsUploadModule,
  ],
  controllers: [EventChatReadController, EventChatMessagesController],
  providers: [
    EventChatClusterConfig,
    EventChatTelemetryService,
    EventChatThrottlerGuard,
    EventChatPushAggregatorService,
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

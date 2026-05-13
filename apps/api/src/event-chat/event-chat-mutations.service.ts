import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { Prisma } from '../prisma-client';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import type { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import type { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import type { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { EventChatMutationModerateService } from './event-chat-mutation-moderate.service';
import { EventChatMutationSendService } from './event-chat-mutation-send.service';

@Injectable()
export class EventChatMutationsService {
  constructor(
    private readonly sendMutation: EventChatMutationSendService,
    private readonly moderateMutation: EventChatMutationModerateService,
  ) {}

  sendMessage(
    eventId: string,
    user: AuthenticatedUser,
    dto: SendEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    return this.sendMutation.sendMessage(eventId, user, dto);
  }

  createSystemMessage(params: {
    eventId: string;
    authorId: string;
    body: string;
    systemPayload: Prisma.InputJsonValue;
  }): Promise<void> {
    return this.sendMutation.createSystemMessage(params);
  }

  editMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: EditEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    return this.moderateMutation.editMessage(eventId, messageId, user, dto);
  }

  setMessagePin(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: PinEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    return this.moderateMutation.setMessagePin(eventId, messageId, user, dto);
  }

  softDeleteMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
  ): Promise<{ data: { ok: true }; meta: { timestamp: string } }> {
    return this.moderateMutation.softDeleteMessage(eventId, messageId, user);
  }
}

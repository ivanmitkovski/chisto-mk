import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import type { ListEventChatQueryDto } from './dto/list-event-chat-query.dto';
import type { MuteChatDto } from './dto/mute-chat.dto';
import type { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import type { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import type { SearchEventChatQueryDto } from './dto/search-event-chat-query.dto';
import type { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { EventChatListService } from './event-chat-list.service';
import { EventChatMutationsService } from './event-chat-mutations.service';
import { EventChatPresenceService } from './event-chat-presence.service';

/**
 * Facade for list/search, message mutations, and presence/read-state helpers.
 */
@Injectable()
export class EventChatService {
  constructor(
    private readonly list: EventChatListService,
    private readonly presence: EventChatPresenceService,
    private readonly mutations: EventChatMutationsService,
  ) {}

  listMessages(
    eventId: string,
    user: AuthenticatedUser,
    query: ListEventChatQueryDto,
  ): ReturnType<EventChatListService['listMessages']> {
    return this.list.listMessages(eventId, user, query);
  }

  searchMessages(
    eventId: string,
    user: AuthenticatedUser,
    query: SearchEventChatQueryDto,
  ): ReturnType<EventChatListService['searchMessages']> {
    return this.list.searchMessages(eventId, user, query);
  }

  listPinnedMessages(
    eventId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatListService['listPinnedMessages']> {
    return this.list.listPinnedMessages(eventId, user);
  }

  sendMessage(
    eventId: string,
    user: AuthenticatedUser,
    dto: SendEventChatMessageDto,
  ): ReturnType<EventChatMutationsService['sendMessage']> {
    return this.mutations.sendMessage(eventId, user, dto);
  }

  createSystemMessage(params: {
    eventId: string;
    authorId: string;
    body: string;
    systemPayload: Prisma.InputJsonValue;
  }): ReturnType<EventChatMutationsService['createSystemMessage']> {
    return this.mutations.createSystemMessage(params);
  }

  editMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: EditEventChatMessageDto,
  ): ReturnType<EventChatMutationsService['editMessage']> {
    return this.mutations.editMessage(eventId, messageId, user, dto);
  }

  setMessagePin(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: PinEventChatMessageDto,
  ): ReturnType<EventChatMutationsService['setMessagePin']> {
    return this.mutations.setMessagePin(eventId, messageId, user, dto);
  }

  getMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatPresenceService['getMuteStatus']> {
    return this.presence.getMuteStatus(eventId, user);
  }

  setMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
    dto: MuteChatDto,
  ): ReturnType<EventChatPresenceService['setMuteStatus']> {
    return this.presence.setMuteStatus(eventId, user, dto);
  }

  listParticipants(eventId: string): ReturnType<EventChatPresenceService['listParticipants']> {
    return this.presence.listParticipants(eventId);
  }

  softDeleteMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatMutationsService['softDeleteMessage']> {
    return this.mutations.softDeleteMessage(eventId, messageId, user);
  }

  patchReadCursor(
    eventId: string,
    user: AuthenticatedUser,
    dto: PatchEventChatReadDto,
  ): ReturnType<EventChatPresenceService['patchReadCursor']> {
    return this.presence.patchReadCursor(eventId, user, dto);
  }

  listReadCursors(eventId: string): ReturnType<EventChatPresenceService['listReadCursors']> {
    return this.presence.listReadCursors(eventId);
  }

  recordTyping(
    eventId: string,
    user: AuthenticatedUser,
    typing: boolean,
  ): ReturnType<EventChatPresenceService['recordTyping']> {
    return this.presence.recordTyping(eventId, user, typing);
  }

  unreadCount(
    eventId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatPresenceService['unreadCount']> {
    return this.presence.unreadCount(eventId, user);
  }
}

import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { MuteChatDto } from './dto/mute-chat.dto';
import type { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import { EventChatPresenceMuteService } from './event-chat-presence-mute.service';
import { EventChatPresenceReadStateService } from './event-chat-presence-read-state.service';
import { EventChatPresenceRosterService } from './event-chat-presence-roster.service';
import { EventChatPresenceTypingService } from './event-chat-presence-typing.service';

@Injectable()
export class EventChatPresenceService {
  constructor(
    private readonly mute: EventChatPresenceMuteService,
    private readonly roster: EventChatPresenceRosterService,
    private readonly readState: EventChatPresenceReadStateService,
    private readonly typing: EventChatPresenceTypingService,
  ) {}

  getMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatPresenceMuteService['getMuteStatus']> {
    return this.mute.getMuteStatus(eventId, user);
  }

  setMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
    dto: MuteChatDto,
  ): ReturnType<EventChatPresenceMuteService['setMuteStatus']> {
    return this.mute.setMuteStatus(eventId, user, dto);
  }

  listParticipants(eventId: string): ReturnType<EventChatPresenceRosterService['listParticipants']> {
    return this.roster.listParticipants(eventId);
  }

  patchReadCursor(
    eventId: string,
    user: AuthenticatedUser,
    dto: PatchEventChatReadDto,
  ): ReturnType<EventChatPresenceReadStateService['patchReadCursor']> {
    return this.readState.patchReadCursor(eventId, user, dto);
  }

  listReadCursors(eventId: string): ReturnType<EventChatPresenceReadStateService['listReadCursors']> {
    return this.readState.listReadCursors(eventId);
  }

  recordTyping(
    eventId: string,
    user: AuthenticatedUser,
    typing: boolean,
  ): ReturnType<EventChatPresenceTypingService['recordTyping']> {
    return this.typing.recordTyping(eventId, user, typing);
  }

  unreadCount(
    eventId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventChatPresenceReadStateService['unreadCount']> {
    return this.readState.unreadCount(eventId, user);
  }
}

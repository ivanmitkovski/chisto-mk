import {
  Body,
  Controller,
  Get,
  Headers,
  MessageEvent as NestMessageEvent,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Sse,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import { concat, defer, finalize, from, interval, map, merge } from 'rxjs';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventChatTypingDto } from './dto/event-chat-typing.dto';
import { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import { SearchEventChatQueryDto } from './dto/search-event-chat-query.dto';
import { MuteChatDto } from './dto/mute-chat.dto';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { ApiEventChatStandardErrors } from './event-chat-openapi.decorators';
import { EventChatListService } from './event-chat-list.service';
import { EventChatPresenceService } from './event-chat-presence.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatThrottlerGuard } from './event-chat-throttler.guard';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('event-chat')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(JwtAuthGuard, EventChatThrottlerGuard, EventChatAccessGuard)
@ApiBearerAuth()
export class EventChatReadController {
  private static readonly HEARTBEAT_INTERVAL_MS = 25_000;

  constructor(
    private readonly list: EventChatListService,
    private readonly presence: EventChatPresenceService,
    private readonly eventChatSse: EventChatSseService,
  ) {}

  @Get(':eventId/chat/unread-count')
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiOperation({ summary: 'Unread chat messages count (from others, after read cursor)' })
  @ApiOkResponse({ description: 'Count payload' })
  @ApiEventChatStandardErrors({ include403: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  unreadCount(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
  ) {
    return this.presence.unreadCount(eventId, user);
  }

  @Get(':eventId/chat/mute')
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'Whether the current user muted push notifications for this chat' })
  @ApiOkResponse({ description: 'Mute status' })
  @ApiEventChatStandardErrors({ include403: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  getMute(@CurrentUser() user: AuthenticatedUser, @Param('eventId', ParseCuidPipe) eventId: string) {
    return this.presence.getMuteStatus(eventId, user);
  }

  @Put(':eventId/chat/mute')
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  @ApiOperation({ summary: 'Mute or unmute push notifications for this event chat' })
  @ApiOkResponse({ description: 'Ack' })
  @ApiEventChatStandardErrors({ include403: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  setMute(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Body() dto: MuteChatDto,
  ) {
    return this.presence.setMuteStatus(eventId, user, dto);
  }

  @Get(':eventId/chat/participants')
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'Chat-eligible members (organizer + participants), count and first 50' })
  @ApiOkResponse({ description: 'Participants payload' })
  @ApiEventChatStandardErrors({ include403: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  listParticipants(@Param('eventId', ParseCuidPipe) eventId: string) {
    return this.presence.listParticipants(eventId);
  }

  @Get(':eventId/chat/pinned')
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'Pinned messages for this event' })
  @ApiOkResponse({ description: 'Pinned messages', type: [EventChatMessageResponseDto] })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  listPinned(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
  ) {
    return this.list.listPinnedMessages(eventId, user);
  }

  @Get(':eventId/chat/search')
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  @ApiOperation({ summary: 'Search messages by body (case-insensitive)' })
  @ApiOkResponse({ description: 'Paginated messages', type: [EventChatMessageResponseDto] })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  searchMessages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Query() query: SearchEventChatQueryDto,
  ) {
    return this.list.searchMessages(eventId, user, query);
  }

  @Sse(':eventId/chat/events')
  @SkipThrottle()
  @ApiOperation({
    summary: 'SSE stream for chat message updates',
    description:
      'Requires `Authorization: Bearer`. Send optional `Last-Event-ID` header (or `last-event-id`) with the last ' +
      'received `id` field to replay buffered events after that id, then continue with live events. ' +
      'Heartbeat events have `data: {"type":"heartbeat"}` and no `id`. See docs/event-chat-stream-events.md.',
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  @ApiResponse({ status: 403, description: 'User may not access this event chat' })
  streamChatEvents(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Headers('last-event-id') lastEventId?: string,
  ) {
    return defer(() => {
      const replayEvents = this.eventChatSse.getReplaySince(eventId, lastEventId);
      const toSse = (event: Record<string, unknown>): NestMessageEvent => ({
        data: event as object,
        type: String(event.type ?? 'message'),
        id: String(event.streamEventId ?? ''),
      });
      const replay$ = from(replayEvents).pipe(map((e) => toSse(e as unknown as Record<string, unknown>)));
      const live$ = this.eventChatSse.getStream(eventId).pipe(
        map((e) => toSse(e as unknown as Record<string, unknown>)),
      );
      const heartbeat$ = interval(EventChatReadController.HEARTBEAT_INTERVAL_MS).pipe(
        map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
      );
      return concat(replay$, merge(live$, heartbeat$)).pipe(finalize(() => undefined));
    });
  }

  @Get(':eventId/chat/read-cursors')
  @ApiOperation({ summary: 'Read cursor snapshot for all chat-eligible members (organizer + participants)' })
  @ApiOkResponse({ description: 'Per-user last read message id and timestamp' })
  @SkipThrottle()
  @ApiEventChatStandardErrors({ include403: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  listReadCursors(@Param('eventId', ParseCuidPipe) eventId: string) {
    return this.presence.listReadCursors(eventId);
  }

  @Post(':eventId/chat/typing')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Broadcast typing presence (Nest throttler + service-side min interval)',
  })
  @ApiOkResponse({ description: 'Ack' })
  @ApiEventChatStandardErrors({ include404: false })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  recordTyping(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Body() dto: EventChatTypingDto,
  ) {
    return this.presence.recordTyping(eventId, user, dto.typing);
  }

  @Patch(':eventId/chat/read')
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'Update read cursor for event chat' })
  @ApiOkResponse({ description: 'Ack' })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  patchRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Body() dto: PatchEventChatReadDto,
  ) {
    return this.presence.patchReadCursor(eventId, user, dto);
  }
}

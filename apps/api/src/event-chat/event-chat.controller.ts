import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  MessageEvent as NestMessageEvent,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Sse,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiConsumes,
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
import { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import { EventChatTypingDto } from './dto/event-chat-typing.dto';
import { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import { ListEventChatQueryDto } from './dto/list-event-chat-query.dto';
import { MuteChatDto } from './dto/mute-chat.dto';
import { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import { SearchEventChatQueryDto } from './dto/search-event-chat-query.dto';
import { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { ApiEventChatStandardErrors } from './event-chat-openapi.decorators';
import { EventChatService } from './event-chat.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatThrottlerGuard } from './event-chat-throttler.guard';
import { EventChatUploadService } from './event-chat-upload.service';

@ApiTags('event-chat')
@Controller('events')
@UseGuards(JwtAuthGuard, EventChatThrottlerGuard, EventChatAccessGuard)
@ApiBearerAuth()
export class EventChatController {
  private static readonly HEARTBEAT_INTERVAL_MS = 25_000;

  constructor(
    private readonly eventChatService: EventChatService,
    private readonly eventChatSse: EventChatSseService,
    private readonly uploadService: EventChatUploadService,
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
    return this.eventChatService.unreadCount(eventId, user);
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
    return this.eventChatService.getMuteStatus(eventId, user);
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
    return this.eventChatService.setMuteStatus(eventId, user, dto);
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
    return this.eventChatService.listParticipants(eventId);
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
    return this.eventChatService.listPinnedMessages(eventId, user);
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
    return this.eventChatService.searchMessages(eventId, user, query);
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
      const heartbeat$ = interval(EventChatController.HEARTBEAT_INTERVAL_MS).pipe(
        map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
      );
      return concat(replay$, merge(live$, heartbeat$)).pipe(
        finalize(() => undefined),
      );
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
    return this.eventChatService.listReadCursors(eventId);
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
    return this.eventChatService.recordTyping(eventId, user, dto.typing);
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
    return this.eventChatService.patchReadCursor(eventId, user, dto);
  }

  @Get(':eventId/chat')
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'List chat messages (newest first)' })
  @ApiOkResponse({ description: 'Paginated messages', type: [EventChatMessageResponseDto] })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  listMessages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Query() query: ListEventChatQueryDto,
  ) {
    return this.eventChatService.listMessages(eventId, user, query);
  }

  @Post(':eventId/chat')
  @Throttle({ default: { limit: 45, ttl: 60_000 } })
  @ApiOperation({ summary: 'Send a chat message' })
  @ApiOkResponse({ description: 'Created message', type: EventChatMessageResponseDto })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  sendMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Body() dto: SendEventChatMessageDto,
  ) {
    return this.eventChatService.sendMessage(eventId, user, dto);
  }

  @Patch(':eventId/chat/:messageId')
  @Throttle({ default: { limit: 45, ttl: 60_000 } })
  @ApiOperation({ summary: 'Edit own text message' })
  @ApiOkResponse({ description: 'Updated message', type: EventChatMessageResponseDto })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  editMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('messageId', ParseCuidPipe) messageId: string,
    @Body() dto: EditEventChatMessageDto,
  ) {
    return this.eventChatService.editMessage(eventId, messageId, user, dto);
  }

  @Post(':eventId/chat/:messageId/pin')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({ summary: 'Pin or unpin a message (organizer only)' })
  @ApiOkResponse({ description: 'Updated message', type: EventChatMessageResponseDto })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  setPin(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('messageId', ParseCuidPipe) messageId: string,
    @Body() dto: PinEventChatMessageDto,
  ) {
    return this.eventChatService.setMessagePin(eventId, messageId, user, dto);
  }

  @Post(':eventId/chat/upload')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({ summary: 'Upload images for a chat message (max 5, 10 MB each)' })
  @ApiConsumes('multipart/form-data')
  @ApiOkResponse({ description: 'Uploaded attachment metadata' })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  @UseInterceptors(FilesInterceptor('files', 5))
  async uploadAttachments(
    @CurrentUser() _user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @UploadedFiles() files: Array<Express.Multer.File>,
  ) {
    const processed = await this.uploadService.processAndUpload(
      eventId,
      files.map((f) => ({
        buffer: f.buffer,
        mimetype: f.mimetype,
        size: f.size,
        originalname: f.originalname,
      })),
    );
    return { data: processed, meta: { timestamp: new Date().toISOString() } };
  }

  @Delete(':eventId/chat/:messageId')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({ summary: 'Soft-delete a chat message (author only)' })
  @ApiOkResponse({ description: 'Ack' })
  @ApiEventChatStandardErrors()
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid bearer token',
    schema: { example: { code: 'UNAUTHORIZED', message: 'Unauthorized' } },
  })
  deleteMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('messageId', ParseCuidPipe) messageId: string,
  ) {
    return this.eventChatService.softDeleteMessage(eventId, messageId, user);
  }
}

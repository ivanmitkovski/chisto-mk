import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
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
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import { ListEventChatQueryDto } from './dto/list-event-chat-query.dto';
import { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { EventChatAccessGuard } from './event-chat-access.guard';
import { ApiEventChatStandardErrors } from './event-chat-openapi.decorators';
import { EventChatListService } from './event-chat-list.service';
import { EventChatMutationsService } from './event-chat-mutations.service';
import { EventChatThrottlerGuard } from './event-chat-throttler.guard';
import {
  EVENT_CHAT_MULTER_MAX_FILE_BYTES,
  EventChatUploadService,
} from './event-chat-upload.service';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('event-chat')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(JwtAuthGuard, EventChatThrottlerGuard, EventChatAccessGuard)
@ApiBearerAuth()
export class EventChatMessagesController {
  constructor(
    private readonly list: EventChatListService,
    private readonly mutations: EventChatMutationsService,
    private readonly uploadService: EventChatUploadService,
  ) {}

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
    return this.list.listMessages(eventId, user, query);
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
    return this.mutations.sendMessage(eventId, user, dto);
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
    return this.mutations.editMessage(eventId, messageId, user, dto);
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
    return this.mutations.setMessagePin(eventId, messageId, user, dto);
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
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      limits: { fileSize: EVENT_CHAT_MULTER_MAX_FILE_BYTES },
    }),
  )
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
    return this.mutations.softDeleteMessage(eventId, messageId, user);
  }
}

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  ParseEnumPipe,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { NotificationInboxService } from './notification-inbox.service';
import { NotificationStateService } from './notification-state.service';
import { NotificationPreferencesService } from './notification-preferences.service';
import { DeviceTokenService } from './device-token.service';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UnregisterDeviceTokenDto } from './dto/unregister-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';
import { ObservabilityStore } from '../observability/observability.store';
import { NotificationType } from '../prisma-client';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('notifications')
@ApiStandardHttpErrorResponses()
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(
    private readonly inbox: NotificationInboxService,
    private readonly state: NotificationStateService,
    private readonly preferences: NotificationPreferencesService,
    private readonly deviceTokens: DeviceTokenService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List notifications for the authenticated user' })
  @ApiOkResponse({ description: 'Paginated notifications' })
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListNotificationsQueryDto,
  ) {
    return this.inbox.listForUser(user, query);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiOkResponse({ description: 'Unread count' })
  unreadCount(@CurrentUser() user: AuthenticatedUser) {
    return this.inbox.getUnreadCount(user);
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get notification summary grouped by type' })
  @ApiOkResponse({ description: 'Grouped counts by notification type' })
  summary(@CurrentUser() user: AuthenticatedUser) {
    return this.inbox.getSummary(user);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  @ApiOkResponse({ description: 'Notification marked as read' })
  async markOneRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.state.markOneRead(user, id);
    return { success: true };
  }

  @Patch(':id/unread')
  @ApiOperation({ summary: 'Mark a notification as unread' })
  @ApiOkResponse({ description: 'Notification marked as unread' })
  async markOneUnread(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.state.markOneUnread(user, id);
    return { success: true };
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiOkResponse({ description: 'Batch update result' })
  markAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.state.markAllRead(user);
  }

  @Patch(':id/archive')
  @ApiOperation({ summary: 'Archive a notification' })
  @ApiOkResponse({ description: 'Notification archived' })
  async archiveOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.state.archiveOne(user, id);
    return { success: true };
  }

  @Patch('archive-all-read')
  @ApiOperation({ summary: 'Archive all read notifications' })
  @ApiOkResponse({ description: 'Batch archive result' })
  archiveAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.state.archiveAllRead(user);
  }

  @Get('preferences')
  @ApiOperation({ summary: 'List notification preferences for current user' })
  @ApiOkResponse({ description: 'Notification preferences' })
  listPreferences(@CurrentUser() user: AuthenticatedUser) {
    return this.preferences.listPreferences(user);
  }

  @Patch('preferences/:type')
  @ApiOperation({ summary: 'Update preference for notification type' })
  @ApiOkResponse({ description: 'Updated notification preference' })
  updatePreference(
    @CurrentUser() user: AuthenticatedUser,
    @Param('type', new ParseEnumPipe(NotificationType)) type: NotificationType,
    @Body() dto: UpdateNotificationPreferenceDto,
  ) {
    return this.preferences.updatePreference(user, type, dto);
  }

  @Post('devices/unregister')
  @ApiOperation({
    summary: 'Unregister a device push token (preferred; token in body avoids proxy access logs)',
  })
  @ApiOkResponse({ description: 'Device token unregistered' })
  async unregisterDeviceBody(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UnregisterDeviceTokenDto,
  ) {
    await this.deviceTokens.unregisterDeviceToken(user, dto.token);
    return { success: true };
  }

  @Post('devices')
  @ApiOperation({ summary: 'Register or update a device push token' })
  @ApiOkResponse({ description: 'Device token registered' })
  registerDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.deviceTokens.registerDeviceToken(user, dto);
  }

  @Delete('devices/:token')
  @ApiOperation({
    summary: 'Unregister a device push token (deprecated: use POST /notifications/devices/unregister)',
  })
  @ApiOkResponse({ description: 'Device token unregistered' })
  async unregisterDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Param('token') token: string,
  ) {
    await this.deviceTokens.unregisterDeviceToken(user, token);
    return { success: true };
  }

  @Get('admin/push-stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiOperation({ summary: 'Push delivery statistics (admin only)' })
  @ApiOkResponse({ description: 'Push delivery stats' })
  pushStats() {
    const s = ObservabilityStore.snapshot();
    return {
      sendsTotal: s.pushSendsTotal,
      sendsSuccess: s.pushSendsSuccess,
      sendsFailure: s.pushSendsFailure,
      sendsRevoked: s.pushSendsRevoked,
      tokenRevocations: s.pushTokenRevocations,
      queueRetries: s.pushQueueRetries,
      inboxReads: s.pushInboxReads,
      queueDepth: s.pushQueueDepth,
      activeLeases: s.pushActiveLeases,
      deadLetterCount: s.pushDeadLetterCount,
    };
  }

  @Get('admin/dead-letters')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiOperation({ summary: 'List dead-letter push outbox entries (admin only)' })
  @ApiOkResponse({ description: 'Dead-letter queue entries' })
  deadLetters(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inbox.listDeadLetters(
      Number(page ?? '1'),
      Number(limit ?? '20'),
    );
  }
}

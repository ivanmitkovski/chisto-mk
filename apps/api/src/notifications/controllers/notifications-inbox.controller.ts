import { Idempotent } from '../../common/idempotency/idempotency.decorator';
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
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { NotificationInboxService } from '../services/notification-inbox.service';
import { NotificationPreferencesService } from '../services/notification-preferences.service';
import { DeviceTokenService } from '../services/device-token.service';
import { ListNotificationsQueryDto } from '../dto/list-notifications-query.dto';
import { RegisterDeviceTokenDto } from '../dto/register-device-token.dto';
import { UnregisterDeviceTokenDto } from '../dto/unregister-device-token.dto';
import { UpdateNotificationPreferenceDto } from '../dto/update-notification-preference.dto';
import { NotificationType } from '../../prisma-client';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('notifications')
@ApiStandardHttpErrorResponses()
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsInboxController {
  constructor(
    private readonly inbox: NotificationInboxService,
    private readonly preferences: NotificationPreferencesService,
    private readonly deviceTokens: DeviceTokenService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List notifications for the authenticated user' })
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: ListNotificationsQueryDto) {
    return this.inbox.listForUser(user, query);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  unreadCount(@CurrentUser() user: AuthenticatedUser) {
    return this.inbox.getUnreadCount(user);
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get notification summary grouped by type' })
  summary(@CurrentUser() user: AuthenticatedUser) {
    return this.inbox.getSummary(user);
  }

  @Get('preferences')
  @ApiOperation({ summary: 'List notification preferences for current user' })
  listPreferences(@CurrentUser() user: AuthenticatedUser) {
    return this.preferences.listPreferences(user);
  }

  @Patch('preferences/:type')
  @ApiOperation({ summary: 'Update preference for notification type' })
  updatePreference(
    @CurrentUser() user: AuthenticatedUser,
    @Param('type', new ParseEnumPipe(NotificationType)) type: NotificationType,
    @Body() dto: UpdateNotificationPreferenceDto,
  ) {
    return this.preferences.updatePreference(user, type, dto);
  }

  @Idempotent('notifications_unregister_device')
  @Post('devices/unregister')
  @ApiOperation({ summary: 'Unregister a device push token (body token)' })
  async unregisterDeviceBody(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UnregisterDeviceTokenDto,
  ) {
    await this.deviceTokens.unregisterDeviceToken(user, dto.token);
    return { success: true };
  }

  @Idempotent('notifications_register_device')
  @Post('devices')
  @ApiOperation({ summary: 'Register or update a device push token' })
  registerDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.deviceTokens.registerDeviceToken(user, dto);
  }

  @Delete('devices/:token')
  @ApiOperation({ summary: 'Unregister device token (deprecated)' })
  async unregisterDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Param('token') token: string,
  ) {
    await this.deviceTokens.unregisterDeviceToken(user, token);
    return { success: true };
  }
}

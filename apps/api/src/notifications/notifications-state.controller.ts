import { Idempotent } from '../common/idempotency/idempotency.decorator';
import { Controller, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { NotificationStateService } from './notification-state.service';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('notifications')
@ApiStandardHttpErrorResponses()
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsStateController {
  constructor(private readonly state: NotificationStateService) {}

  @Idempotent('notifications_opened')
  @Post(':id/opened')
  @ApiOperation({ summary: 'Record notification opened' })
  async recordOpened(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.state.recordOpened(user, id);
    return { success: true };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  async markOneRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.state.markOneRead(user, id);
    return { success: true };
  }

  @Patch(':id/unread')
  @ApiOperation({ summary: 'Mark a notification as unread' })
  async markOneUnread(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.state.markOneUnread(user, id);
    return { success: true };
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  markAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.state.markAllRead(user);
  }

  @Patch(':id/archive')
  @ApiOperation({ summary: 'Archive a notification' })
  async archiveOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.state.archiveOne(user, id);
    return { success: true };
  }

  @Patch('archive-all-read')
  @ApiOperation({ summary: 'Archive all read notifications' })
  archiveAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.state.archiveAllRead(user);
  }
}

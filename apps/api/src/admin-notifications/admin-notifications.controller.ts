import { Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AdminNotificationsService } from './admin-notifications.service';
import { ListAdminNotificationsQueryDto } from './dto/list-admin-notifications.dto';

@ApiTags('admin-notifications')
@Controller('admin/notifications')
export class AdminNotificationsController {
  constructor(private readonly notificationsService: AdminNotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List admin notifications for the current console user' })
  @ApiOkResponse({ description: 'Notifications fetched successfully' })
  listForAdmin(
    @CurrentUser() admin: AuthenticatedUser,
    @Query() query: ListAdminNotificationsQueryDto,
  ) {
    return this.notificationsService.listForAdmin(admin, query);
  }

  @Patch(':id/read')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark a single notification as read' })
  @ApiOkResponse({ description: 'Notification marked as read' })
  async markOneRead(@CurrentUser() admin: AuthenticatedUser, @Param('id') id: string) {
    await this.notificationsService.markOneRead(admin, id);
    return { success: true };
  }

  @Patch('read-all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark all notifications as read for the current admin' })
  @ApiOkResponse({ description: 'Notifications marked as read' })
  markAllRead(@CurrentUser() admin: AuthenticatedUser) {
    return this.notificationsService.markAllRead(admin);
  }
}


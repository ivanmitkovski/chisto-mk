import { Controller, Get, Headers, Param, Patch, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AdminNotificationsService } from '../services/admin-notifications.service';
import { ListAdminNotificationsQueryDto } from '../dto/list-admin-notifications.dto';
import { localeFromAcceptLanguage } from '../../common/utils/format-relative-time-since';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('admin-notifications')
@ApiStandardHttpErrorResponses()
@Controller('admin/notifications')
export class AdminNotificationsController {
  constructor(private readonly notificationsService: AdminNotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List admin notifications for the current console user' })
  @ApiOkResponse({ description: 'Notifications fetched successfully' })
  listForAdmin(
    @CurrentUser() admin: AuthenticatedUser,
    @Query() query: ListAdminNotificationsQueryDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    return this.notificationsService.listForAdmin(
      admin,
      query,
      localeFromAcceptLanguage(acceptLanguage),
    );
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/read')
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark a single notification as read' })
  @ApiOkResponse({ description: 'Notification marked as read' })
  async markOneRead(@CurrentUser() admin: AuthenticatedUser, @Param('id') id: string) {
    await this.notificationsService.markOneRead(admin, id);
    return { success: true };
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch('read-all')
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark all notifications as read for the current admin' })
  @ApiOkResponse({ description: 'Notifications marked as read' })
  markAllRead(@CurrentUser() admin: AuthenticatedUser) {
    return this.notificationsService.markAllRead(admin);
  }
}


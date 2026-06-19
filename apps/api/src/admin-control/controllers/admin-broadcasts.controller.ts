import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { CreateBroadcastDto, UpdateBroadcastDto, AudiencePreviewDto, AudienceUserLookupDto } from '../dto/admin-broadcast.dto';
import { AdminBroadcastsService } from '../services/admin-broadcasts.service';
import { AdminBroadcastsDispatchService } from '../services/admin-broadcasts-dispatch.service';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('admin-broadcasts')
@Controller('admin/broadcasts')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminBroadcastsController {
  constructor(
    private readonly broadcasts: AdminBroadcastsService,
    private readonly dispatch: AdminBroadcastsDispatchService,
  ) {}

  @Get()
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiOperation({ summary: 'List broadcast campaigns' })
  list() {
    return this.broadcasts.list();
  }

  // safe-to-retry: read-only audience count preview
  @Post('audience-preview')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiOperation({ summary: 'Preview broadcast audience recipient count' })
  previewAudience(@Body() body: AudiencePreviewDto) {
    return this.broadcasts.previewAudience({
      audience: body.audience,
      ...(body.audienceUserIds !== undefined ? { audienceUserIds: body.audienceUserIds } : {}),
    });
  }

  // safe-to-retry: read-only user lookup for audience chips
  @Post('audience-users/lookup')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiOperation({ summary: 'Lookup users for broadcast audience chips' })
  lookupAudienceUsers(@Body() body: AudienceUserLookupDto) {
    return this.broadcasts.lookupAudienceUsers(body.userIds);
  }

  @Get(':id')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:read'])
  @ApiOperation({ summary: 'Get broadcast campaign by id' })
  getById(@Param('id') id: string) {
    return this.broadcasts.getById(id);
  }

  @Idempotent('admin_broadcast_create')
  @Post()
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:broadcast'])
  @ApiOperation({ summary: 'Create broadcast campaign' })
  create(@Body() body: CreateBroadcastDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.broadcasts.create(
      {
        title: body.title,
        body: body.body,
        type: body.type ?? 'SYSTEM',
        deeplink: body.deeplink,
        audience: body.audience,
        audienceUserIds: body.audienceUserIds,
        scheduledAt: body.scheduledAt,
      },
      actor,
    );
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:broadcast'])
  @ApiOperation({ summary: 'Update broadcast campaign' })
  update(@Param('id') id: string, @Body() body: UpdateBroadcastDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.broadcasts.update(id, body, actor);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete(':id')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:broadcast'])
  @ApiOperation({ summary: 'Delete broadcast campaign' })
  async remove(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    await this.broadcasts.delete(id, actor);
    return { deleted: true };
  }

  @Idempotent('admin_broadcast_send')
  @Post(':id/send')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:broadcast'])
  @ApiOperation({ summary: 'Send broadcast campaign' })
  send(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.dispatch.send(id, actor);
  }

  @Idempotent('admin_broadcast_cancel')
  @Patch(':id/cancel')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['notifications:broadcast'])
  @ApiOperation({ summary: 'Cancel broadcast campaign' })
  cancel(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.broadcasts.cancel(id, actor);
  }
}

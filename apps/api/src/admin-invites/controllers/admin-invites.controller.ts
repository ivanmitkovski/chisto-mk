import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { SUPER_ADMIN_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AdminInvitesService } from '../services/admin-invites.service';
import { CreateAdminInviteDto } from '../dto/create-admin-invite.dto';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('admin-invites')
@ApiStandardHttpErrorResponses()
@Controller('admin/invites')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminInvitesController {
  constructor(private readonly invites: AdminInvitesService) {}

  @Get()
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['team:read'])
  @ApiOperation({ summary: 'List admin invites (super admin only)' })
  @ApiOkResponse({ description: 'Invites listed' })
  list() {
    return this.invites.list();
  }

  @Idempotent('admin_invite_create')
  @Post()
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['team:write'])
  @ApiOperation({ summary: 'Create admin invite (super admin only)' })
  @ApiOkResponse({ description: 'Invite created' })
  create(@Body() dto: CreateAdminInviteDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.invites.create(dto, actor);
  }

  @Idempotent('admin_invite_resend')
  @Post(':id/resend')
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['team:write'])
  @ApiOperation({ summary: 'Resend admin invite (super admin only)' })
  @ApiOkResponse({ description: 'Invite resent' })
  resend(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.invites.resend(id, actor);
  }

  @Idempotent('admin_invite_revoke')
  @Post(':id/revoke')
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['team:write'])
  @ApiOperation({ summary: 'Revoke admin invite (super admin only)' })
  @ApiOkResponse({ description: 'Invite revoked' })
  revoke(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.invites.revoke(id, actor);
  }
}

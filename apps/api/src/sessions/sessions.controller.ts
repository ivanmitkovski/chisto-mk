import { Controller, Delete, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { SessionsService } from './sessions.service';

@ApiTags('admin-sessions')
@Controller('admin/sessions')
export class SessionsController {
  constructor(private readonly sessionsService: SessionsService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List active sessions for the current admin' })
  @ApiOkResponse({ description: 'Sessions listed' })
  listMine(@CurrentUser() admin: AuthenticatedUser) {
    return this.sessionsService.listMine(admin);
  }

  @Delete('me/others')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke all sessions except the current access token session' })
  @ApiOkResponse({ description: 'Other sessions revoked' })
  revokeOthers(@CurrentUser() admin: AuthenticatedUser) {
    return this.sessionsService.revokeOthers(admin);
  }
}

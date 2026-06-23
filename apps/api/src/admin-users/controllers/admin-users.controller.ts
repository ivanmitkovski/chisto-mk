import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES, SUPER_ADMIN_ROLES } from '../../auth/constants/admin-roles';
import { AdminUsersService } from '../services/admin-users.service';
import { BulkAdminUsersDto } from '../dto/bulk-admin-users.dto';
import { CreateUserModerationNoteDto } from '../dto/create-user-moderation-note.dto';
import { ListAdminUsersQueryDto } from '../dto/list-admin-users-query.dto';
import { PatchAdminUserDto } from '../dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from '../dto/patch-admin-user-role.dto';
import {
  AdminConfirmEmailChangeDto,
  AdminRequestEmailChangeDto,
} from '../dto/admin-email-change.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('admin-users')
@ApiStandardHttpErrorResponses()
@Controller('admin/users')
export class AdminUsersController {
  constructor(private readonly adminUsersService: AdminUsersService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List users' })
  @ApiOkResponse({ description: 'Users listed' })
  list(@Query() query: ListAdminUsersQueryDto) {
    return this.adminUsersService.list(query);
  }

  @Idempotent('admin-users_admin-users_37')
  @Post('bulk')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Bulk update users' })
  @ApiOkResponse({ description: 'Bulk update result' })
  bulk(@Body() dto: BulkAdminUsersDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.adminUsersService.bulk(dto, actor);
  }

  @Get(':id/moderation-notes')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List moderator notes for user' })
  getModerationNotes(
    @Param('id') id: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.adminUsersService.getModerationNotes(id, page ?? 1, limit ?? 20);
  }

  @Get(':id/status-history')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List status change history for user' })
  getStatusHistory(
    @Param('id') id: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.adminUsersService.getStatusHistory(id, page ?? 1, limit ?? 20);
  }

  @Idempotent('admin-users_moderation_note_create')
  @Post(':id/moderation-notes')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add moderator note for user' })
  createModerationNote(
    @Param('id') id: string,
    @Body() dto: CreateUserModerationNoteDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.createModerationNote(id, dto.body, actor);
  }

  @Get(':id/safety-summary')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user safety and trust summary' })
  @ApiOkResponse({ description: 'User safety summary' })
  getSafetySummary(@Param('id') id: string) {
    return this.adminUsersService.getSafetySummary(id);
  }

  @Get(':id/data-export')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Export user data (admin DSAR)' })
  @ApiOkResponse({ description: 'User data export JSON' })
  getDataExport(@Param('id') id: string) {
    return this.adminUsersService.getDataExport(id);
  }

  @Get(':id/audit')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get audit entries for user' })
  @ApiOkResponse({ description: 'User audit log' })
  getAudit(
    @Param('id') id: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.adminUsersService.getAudit(id, page ?? 1, limit ?? 20);
  }

  @Get(':id/sessions')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get sessions for user' })
  @ApiOkResponse({ description: 'User sessions' })
  getSessions(@Param('id') id: string) {
    return this.adminUsersService.getSessions(id);
  }

  // safe-to-retry: repeated revoke-all is acceptable
  @Post(':id/sessions/revoke-all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke all sessions for user' })
  @ApiOkResponse({ description: 'All sessions revoked' })
  revokeAllSessions(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.adminUsersService.revokeAllSessions(id, actor);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete(':id/sessions/:sessionId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke a user session' })
  @ApiOkResponse({ description: 'Session revoked' })
  revokeSession(
    @Param('id') id: string,
    @Param('sessionId') sessionId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.revokeSession(id, sessionId, actor);
  }

  @Idempotent('admin-users_email_change_request')
  @Post(':id/email/change-request')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Request admin-assisted email change (OTP to new address)' })
  @ApiOkResponse({ description: 'Verification code sent to new email' })
  requestEmailChange(
    @Param('id') id: string,
    @Body() dto: AdminRequestEmailChangeDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.requestEmailChange(id, dto, actor);
  }

  @Idempotent('admin-users_email_change_confirm')
  @Post(':id/email/confirm')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Confirm admin-assisted email change with OTP' })
  @ApiOkResponse({ description: 'Email updated' })
  confirmEmailChange(
    @Param('id') id: string,
    @Body() dto: AdminConfirmEmailChangeDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.confirmEmailChange(id, dto, actor);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user detail' })
  @ApiOkResponse({ description: 'User detail' })
  findOne(@Param('id') id: string) {
    return this.adminUsersService.findOne(id);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user profile fields or status (not role)' })
  @ApiOkResponse({ description: 'User updated' })
  patch(
    @Param('id') id: string,
    @Body() dto: PatchAdminUserDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.patch(id, dto, actor);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/role')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...SUPER_ADMIN_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change user role (super admin only)' })
  @ApiOkResponse({ description: 'User role updated' })
  patchRole(
    @Param('id') id: string,
    @Body() dto: PatchAdminUserRoleDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.adminUsersService.patchRole(id, dto, actor);
  }
}

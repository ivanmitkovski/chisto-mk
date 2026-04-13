import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
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
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES, SUPER_ADMIN_ROLES } from '../auth/admin-roles';
import { AdminUsersService } from './admin-users.service';
import { BulkAdminUsersDto } from './dto/bulk-admin-users.dto';
import { ListAdminUsersQueryDto } from './dto/list-admin-users-query.dto';
import { PatchAdminUserDto } from './dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from './dto/patch-admin-user-role.dto';

@ApiTags('admin-users')
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

  @Post('bulk')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Bulk update users' })
  @ApiOkResponse({ description: 'Bulk update result' })
  bulk(@Body() dto: BulkAdminUsersDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.adminUsersService.bulk(dto, actor);
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

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user detail' })
  @ApiOkResponse({ description: 'User detail' })
  findOne(@Param('id') id: string) {
    return this.adminUsersService.findOne(id);
  }

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

import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AdminService, AdminOverviewStats, AdminSecurityOverview } from './admin.service';

@ApiTags('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('overview')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get high-level admin overview metrics' })
  @ApiOkResponse({ description: 'Overview metrics fetched successfully' })
  getOverview(): Promise<AdminOverviewStats> {
    return this.adminService.getOverview();
  }

  @Get('security/overview')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get admin security overview (sessions and recent activity)' })
  @ApiOkResponse({ description: 'Security overview fetched successfully' })
  getSecurityOverview(@CurrentUser() admin: AuthenticatedUser): Promise<AdminSecurityOverview> {
    return this.adminService.getSecurityOverview(admin);
  }
}


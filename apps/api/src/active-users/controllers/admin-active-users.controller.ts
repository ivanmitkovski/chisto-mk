import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { AuditService } from '../../audit/services/audit.service';
import { clientIp } from '../../sites/http/client-ip';
import { PrismaService } from '../../prisma/prisma.service';
import {
  ActiveUsersListQueryDto,
  ActivityFeedQueryDto,
  CreateAdminAlertRuleDto,
  UpdateAdminAlertRuleDto,
} from '../dto/admin-active-users.dto';
import { ActiveUsersAdminService } from '../services/active-users-admin.service';

@ApiTags('admin-active-users')
@ApiStandardHttpErrorResponses()
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminActiveUsersController {
  constructor(
    private readonly admin: ActiveUsersAdminService,
    private readonly audit: AuditService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('active-users/summary')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Live active users summary with trends and peaks' })
  async summary(@CurrentUser() user: AuthenticatedUser, @Req() req: Request) {
    void this.audit.log({
      actorId: user.userId,
      action: 'ANALYTICS_DASHBOARD_VIEW',
      resourceType: 'active_users',
      ipAddress: clientIp(req, req.headers['x-forwarded-for'] as string | undefined),
    });
    return this.admin.getSummary();
  }

  @Get('active-users')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Paginated active users list' })
  list(@Query() query: ActiveUsersListQueryDto) {
    return this.admin.listActiveUsers({
      page: query.page ?? 1,
      limit: query.limit ?? 25,
      ...(query.status ? { status: query.status } : {}),
      ...(query.platform ? { platform: query.platform } : {}),
      ...(query.search ? { search: query.search } : {}),
    });
  }

  @Get('active-users/activity-feed')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Live activity feed (paginated)' })
  activityFeed(@Query() query: ActivityFeedQueryDto) {
    return this.admin.getActivityFeed({
      page: query.page ?? 1,
      limit: query.limit ?? 50,
      ...(query.type ? { type: query.type } : {}),
      ...(query.search ? { search: query.search } : {}),
    });
  }

  @Get('active-users/geo')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Privacy-clustered geo aggregation (country/city counts)' })
  geo() {
    return this.admin.getGeoClusters();
  }

  @Get('active-users/:userId')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'User details with sessions and navigation timeline' })
  userDetails(@Param('userId') userId: string) {
    return this.admin.getUserDetails(userId);
  }

  @Get('analytics/engagement')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'DAU/WAU/MAU engagement analytics' })
  engagement() {
    return this.admin.getEngagementAnalytics();
  }

  @Get('analytics/realtime')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Real-time operational metrics' })
  realtime() {
    return this.admin.getRealtimeAnalytics();
  }

  @Get('alert-rules')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'List admin alert rules' })
  listAlertRules() {
    return this.prisma.adminAlertRule.findMany({ orderBy: { createdAt: 'desc' } });
  }

  @Idempotent('admin_alert_rule_create')
  @Post('alert-rules')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOperation({ summary: 'Create admin alert rule' })
  createAlertRule(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateAdminAlertRuleDto) {
    return this.prisma.adminAlertRule.create({
      data: {
        metric: dto.metric as never,
        threshold: dto.threshold,
        windowSeconds: dto.windowSeconds ?? 300,
        comparator: (dto.comparator ?? 'GT') as never,
        createdById: user.userId,
      },
    });
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch('alert-rules/:id')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  updateAlertRule(@Param('id') id: string, @Body() dto: UpdateAdminAlertRuleDto) {
    return this.prisma.adminAlertRule.update({
      where: { id },
      data: {
        ...(dto.threshold != null ? { threshold: dto.threshold } : {}),
        ...(dto.enabled != null ? { enabled: dto.enabled } : {}),
      },
    });
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete('alert-rules/:id')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['analytics:read'])
  @ApiOkResponse()
  async deleteAlertRule(@Param('id') id: string) {
    await this.prisma.adminAlertRule.delete({ where: { id } });
    return { ok: true };
  }
}

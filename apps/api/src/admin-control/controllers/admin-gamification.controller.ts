import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { RankingsService } from '../../gamification/services/rankings.service';
import {
  AdminWeeklyRankingsQueryDto,
  AdminWeeklyRankingsResponseDto,
} from '../dto/admin-weekly-rankings.dto';
import { AdminGamificationService, GamificationConfig } from '../services/admin-gamification.service';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('admin-gamification')
@Controller('admin/gamification')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminGamificationController {
  constructor(
    private readonly gamification: AdminGamificationService,
    private readonly rankings: RankingsService,
  ) {}

  @Get('config')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:read'])
  @ApiOperation({ summary: 'Get gamification config' })
  getConfig() {
    return this.gamification.getConfig();
  }

  @Idempotent('admin_gamification_config')
  @Patch('config')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:write'])
  @ApiOperation({ summary: 'Update gamification config' })
  updateConfig(@Body() body: GamificationConfig, @CurrentUser() actor: AuthenticatedUser) {
    return this.gamification.updateConfig(body, actor);
  }

  @Get('users/:userId/points')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:read'])
  @ApiOperation({ summary: 'List user point ledger' })
  listUserPoints(
    @Param('userId') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.gamification.listUserPoints(userId, page ? Number(page) : 1, limit ? Number(limit) : 50);
  }

  @Idempotent('admin_gamification_points_adjust')
  @Post('users/:userId/points/adjust')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:write'])
  @ApiOperation({ summary: 'Adjust user points' })
  adjustPoints(
    @Param('userId') userId: string,
    @Body() body: { delta: number; reasonCode: string; note?: string },
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.gamification.adjustPoints(userId, body.delta, body.reasonCode, actor, body.note);
  }

  @Idempotent('admin_gamification_report_credits_adjust')
  @Post('users/:userId/report-credits/adjust')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:write'])
  @ApiOperation({ summary: 'Adjust user report credits' })
  adjustReportCredits(
    @Param('userId') userId: string,
    @Body() body: { delta: number; reasonCode: string; note?: string },
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.gamification.adjustReportCredits(userId, body.delta, body.reasonCode, actor, body.note);
  }

  @Get('rankings/weekly')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['gamification:read'])
  @ApiOperation({ summary: 'Weekly rankings snapshot (admin view with full user identity)' })
  @ApiOkResponse({ type: AdminWeeklyRankingsResponseDto })
  async weeklyRankings(@Query() query: AdminWeeklyRankingsQueryDto): Promise<AdminWeeklyRankingsResponseDto> {
    const ref = query.weekStartsAt ? new Date(query.weekStartsAt) : new Date();
    return this.rankings.getAdminWeeklyLeaderboard(query.limit ?? 50, ref);
  }
}

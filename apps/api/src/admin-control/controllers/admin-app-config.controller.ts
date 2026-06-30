import { Body, Controller, Get, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES, SUPER_ADMIN_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  AdminAppConfigService,
  FeedRankingConfig,
  ReportCreditsConfig,
} from '../services/admin-app-config.service';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('admin-app-config')
@Controller('admin/app-config')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminAppConfigController {
  constructor(private readonly appConfig: AdminAppConfigService) {}

  @Get('report-credits')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['app-config:read'])
  getReportCredits() {
    return this.appConfig.getReportCredits();
  }

  @Idempotent('admin_app_config_report_credits')
  @Patch('report-credits')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['app-config:write'])
  updateReportCredits(@Body() body: ReportCreditsConfig, @CurrentUser() actor: AuthenticatedUser) {
    return this.appConfig.updateReportCredits(body, actor);
  }

  @Get('feed-ranking')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['app-config:read'])
  getFeedRanking() {
    return this.appConfig.getFeedRanking();
  }

  @Idempotent('admin_app_config_feed_ranking')
  @Patch('feed-ranking')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['app-config:write'])
  updateFeedRanking(@Body() body: FeedRankingConfig, @CurrentUser() actor: AuthenticatedUser) {
    return this.appConfig.updateFeedRanking(body, actor);
  }

  @Get('organizer-quiz')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['config:read'])
  getOrganizerQuiz(@Query('locale') locale?: string) {
    return this.appConfig.getOrganizerQuiz(locale ?? 'en');
  }

  @Idempotent('admin_app_config_organizer_quiz')
  @Patch('organizer-quiz')
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['config:write'])
  updateOrganizerQuiz(
    @Query('locale') locale: string | undefined,
    @Body() body: Record<string, unknown>,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.appConfig.updateOrganizerQuiz(locale ?? 'en', body, actor);
  }

  @Get('terms-version')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['config:read'])
  getTermsVersion() {
    return this.appConfig.getTermsVersion();
  }

  @Idempotent('admin_app_config_terms_version')
  @Patch('terms-version')
  @Roles(...SUPER_ADMIN_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['config:write'])
  updateTermsVersion(@Body() body: { version: string }, @CurrentUser() actor: AuthenticatedUser) {
    return this.appConfig.updateTermsVersion(body.version, actor);
  }
}

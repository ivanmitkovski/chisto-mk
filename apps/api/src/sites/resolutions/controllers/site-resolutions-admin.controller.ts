import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from '../../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../../auth/constants/admin-permissions';
import { JwtAuthGuard } from '../../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../../auth/guards/permissions.guard';
import { Roles } from '../../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../../auth/decorators/require-permission.decorator';
import { CurrentUser } from '../../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../../auth/types/authenticated-user.type';
import { ParseCuidPipe } from '../../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../../common/openapi/standard-http-error-responses.decorator';
import { Idempotent } from '../../../common/idempotency/idempotency.decorator';
import {
  AdminSiteResolutionListResponseDto,
  ListAdminSiteResolutionsQueryDto,
} from '../dto/admin-site-resolution-list.dto';
import { UpdateSiteResolutionStatusDto } from '../dto/update-site-resolution-status.dto';
import { SiteResolutionQueryService } from '../services/site-resolution-query.service';
import { SiteResolutionModerationService } from '../services/site-resolution-moderation.service';
import { SiteResolutionResponseDto } from '../dto/site-resolution-response.dto';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
/** Admin-only routes use `/sites/admin/*` so they are not captured by `GET /sites/:id`. */
@Controller('sites/admin/resolutions')
export class SiteResolutionsAdminController {
  constructor(
    private readonly query: SiteResolutionQueryService,
    private readonly moderation: SiteResolutionModerationService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['sites:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List site resolution submissions for admin moderation' })
  @ApiOkResponse({ type: AdminSiteResolutionListResponseDto })
  list(@Query() query: ListAdminSiteResolutionsQueryDto): Promise<AdminSiteResolutionListResponseDto> {
    return this.query.listForAdmin({
      page: query.page,
      limit: query.limit,
      ...(query.status != null ? { status: query.status } : {}),
      ...(query.siteId != null ? { siteId: query.siteId } : {}),
    });
  }

  @Idempotent('site_resolution_moderate')
  @Patch(':resolutionId/status')
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['sites:resolve'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve or reject a site resolution submission' })
  @ApiOkResponse({ type: SiteResolutionResponseDto })
  async updateStatus(
    @Param('resolutionId', ParseCuidPipe) resolutionId: string,
    @Body() dto: UpdateSiteResolutionStatusDto,
    @CurrentUser() admin: AuthenticatedUser,
  ): Promise<SiteResolutionResponseDto> {
    const updated = await this.moderation.updateStatus(resolutionId, dto, admin);
    return {
      id: updated.id,
      siteId: updated.siteId,
      status: updated.status,
      mediaUrls: updated.mediaUrls,
      note: updated.note,
      isReporterSubmission: updated.isReporterSubmission,
      createdAt: updated.createdAt.toISOString(),
      moderatedAt: updated.moderatedAt?.toISOString() ?? null,
      submitter: null,
    };
  }
}

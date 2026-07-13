import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import type { Response } from 'express';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../../auth/guards/optional-jwt-auth.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { ListSiteMediaQueryDto } from '../dto/list-site-media-query.dto';
import { UpdateSiteArchiveDto } from '../dto/update-site-archive.dto';
import { UpdateSiteStatusDto } from '../dto/update-site-status.dto';
import { SiteDetailResponseDto } from '../dto/site-detail-response.dto';
import { SitePublicShareCardResponseDto } from '../dto/site-public-share-card.dto';
import { SiteMediaListResponseDto } from '../dto/site-media-response.dto';
import { SiteCoReportersListResponseDto } from '../dto/site-co-reporters-response.dto';
import { ListSiteCoReportersQueryDto } from '../dto/list-site-co-reporters-query.dto';
import { CleanupEvidenceListResponseDto } from '../resolutions/dto/cleanup-evidence.dto';
import { SiteCleanupEvidenceService } from '../resolutions/services/site-cleanup-evidence.service';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { SitesAdminService } from '../services/sites-admin.service';
import { SitesDetailService } from '../services/sites-detail.service';
import { SitesMediaService } from '../services/sites-media.service';
import { SitesShareCardQueryService } from '../services/sites-share-card-query.service';
import { SiteCoReportersListService } from '../services/site-co-reporters-list.service';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { sendPublicMediaRedirect } from '../../common/http/public-media-redirect';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesDetailController {
  constructor(
    private readonly sitesDetail: SitesDetailService,
    private readonly sitesMedia: SitesMediaService,
    private readonly sitesAdmin: SitesAdminService,
    private readonly coReportersList: SiteCoReportersListService,
    private readonly cleanupEvidence: SiteCleanupEvidenceService,
    private readonly shareCard: SitesShareCardQueryService,
  ) {}

  @Get(':id/share-card')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({
    summary: 'Public share card for HTTPS `/sites/:id` landing (public visibility only)',
  })
  @ApiOkResponse({ type: SitePublicShareCardResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found or not publicly visible' })
  @ApiBadRequestResponse({
    description: 'Malformed site id',
    schema: { example: { code: 'INVALID_CUID', message: 'Invalid resource id' } },
  })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  getPublicShareCard(@Param('id', ParseCuidPipe) id: string) {
    return this.shareCard.findPublicShareCard(id);
  }

  /**
   * Stable media URL for share landing ISR HTML. Redirects to a freshly signed S3 GET URL.
   */
  @Get(':id/share-media/:index')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60_000, limit: 300 } })
  @ApiOperation({ summary: 'Redirect to a freshly signed URL for public site share media' })
  @ApiResponse({ status: 302, description: 'Redirect to a short-lived signed S3 GET URL' })
  @ApiNotFoundResponse({ description: 'Site or media slot not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async redirectShareMedia(
    @Param('id', ParseCuidPipe) id: string,
    @Param('index', ParseIntPipe) index: number,
    @Res() res: Response,
  ): Promise<void> {
    const signed = await this.shareCard.getShareMediaSignedUrl(id, index);
    sendPublicMediaRedirect(res, signed, this.shareCard.getMediaRedirectMaxAgeSeconds());
  }

  @Get(':id/share-evidence/:index')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60_000, limit: 300 } })
  @ApiOperation({ summary: 'Redirect to a freshly signed URL for public site cleanup evidence' })
  @ApiResponse({ status: 302, description: 'Redirect to a short-lived signed S3 GET URL' })
  @ApiNotFoundResponse({ description: 'Site or evidence slot not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async redirectShareEvidence(
    @Param('id', ParseCuidPipe) id: string,
    @Param('index', ParseIntPipe) index: number,
    @Res() res: Response,
  ): Promise<void> {
    const signed = await this.shareCard.getShareEvidenceSignedUrl(id, index);
    sendPublicMediaRedirect(res, signed, this.shareCard.getMediaRedirectMaxAgeSeconds());
  }

  @Get(':id/share-avatar')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60_000, limit: 300 } })
  @ApiOperation({ summary: 'Redirect to a freshly signed URL for the public share reporter avatar' })
  @ApiResponse({ status: 302, description: 'Redirect to a short-lived signed S3 GET URL' })
  @ApiNotFoundResponse({ description: 'Site or avatar not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async redirectShareAvatar(
    @Param('id', ParseCuidPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const signed = await this.shareCard.getShareAvatarSignedUrl(id);
    sendPublicMediaRedirect(res, signed, this.shareCard.getMediaRedirectMaxAgeSeconds());
  }

  @Get(':id/cleanup-evidence')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unified after-cleanup evidence gallery for a site' })
  @ApiOkResponse({ type: CleanupEvidenceListResponseDto })
  findCleanupEvidence(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: PaginationQueryDto20,
  ) {
    return this.cleanupEvidence.listForSite(id, query);
  }

  @Get(':id')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get site details with reports' })
  @ApiOkResponse({ description: 'Site fetched successfully', type: SiteDetailResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findOne(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user?: AuthenticatedUser) {
    return this.sitesDetail.findOne(id, user);
  }

  @Get(':id/media')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all site media with pagination' })
  @ApiOkResponse({ description: 'Site media fetched successfully', type: SiteMediaListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findMedia(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteMediaQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.sitesMedia.findSiteMedia(id, query, user);
  }

  @Get(':id/co-reporters')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List co-reporters for a pollution site (original reporter + merged co-reporters)' })
  @ApiOkResponse({ description: 'Site co-reporters fetched successfully', type: SiteCoReportersListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findCoReporters(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteCoReportersQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.coReportersList.findSiteCoReporters(id, query, user);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update canonical site lifecycle status' })
  @ApiOkResponse({ description: 'Site status updated successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiBadRequestResponse({ description: 'Invalid status transition' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  updateStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateSiteStatusDto,
    @CurrentUser() admin: AuthenticatedUser,
  ) {
    return this.sitesAdmin.updateStatus(id, dto, admin);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/archive')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Archive or unarchive site from default map visibility' })
  @ApiOkResponse({ description: 'Site archive moderation updated successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiBadRequestResponse({ description: 'Invalid archive moderation payload' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  updateArchiveStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateSiteArchiveDto,
    @CurrentUser() admin: AuthenticatedUser,
  ) {
    return this.sitesAdmin.updateArchiveStatus(id, dto, admin);
  }
}

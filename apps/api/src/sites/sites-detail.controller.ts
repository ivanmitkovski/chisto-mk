import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { UpdateSiteArchiveDto } from './dto/update-site-archive.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { SiteDetailResponseDto } from './dto/site-detail-response.dto';
import { SiteMediaListResponseDto } from './dto/site-media-response.dto';
import { SitesAdminService } from './sites-admin.service';
import { SitesDetailService } from './sites-detail.service';
import { SitesMediaService } from './sites-media.service';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesDetailController {
  constructor(
    private readonly sitesDetail: SitesDetailService,
    private readonly sitesMedia: SitesMediaService,
    private readonly sitesAdmin: SitesAdminService,
  ) {}

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
  ) {
    return this.sitesMedia.findSiteMedia(id, query);
  }

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

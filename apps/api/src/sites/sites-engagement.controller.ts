import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';
import { ListSiteUpvotesQueryDto } from './dto/list-site-upvotes-query.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SiteShareLinkRequestDto } from './dto/site-share-link-request.dto';
import { SiteShareLinkResponseDto } from './dto/site-share-link-response.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { SiteEngagementSnapshotResponseDto } from './dto/site-engagement-snapshot-response.dto';
import { SiteUpvotersListResponseDto } from './dto/site-upvoters-response.dto';
import { SitesEngagementActionsService } from './sites-engagement-actions.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesSiteUpvotesListService } from './sites-site-upvotes-list.service';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesEngagementController {
  constructor(
    private readonly upvotesList: SitesSiteUpvotesListService,
    private readonly engagementActions: SitesEngagementActionsService,
    private readonly sitesFeed: SitesFeedService,
  ) {}

  @Get(':id/upvotes')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List users who upvoted this site' })
  @ApiOkResponse({ description: 'Site upvotes fetched successfully', type: SiteUpvotersListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findUpvotes(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteUpvotesQueryDto,
    @CurrentUser() _user?: AuthenticatedUser,
  ) {
    return this.upvotesList.findSiteUpvotes(id, query);
  }

  @Post(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upvote site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  upvote(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.engagementActions.upvoteSite(id, user);
  }

  @Delete(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove upvote from site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  removeUpvote(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.engagementActions.removeSiteUpvote(id, user);
  }

  @Post(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  save(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.engagementActions.saveSite(id, user);
  }

  @Delete(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove saved site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  unsave(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.engagementActions.unsaveSite(id, user);
  }

  @Post(':id/share')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track site share event' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  shareSite(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: ShareSiteDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.engagementActions.shareSite(id, dto, user);
  }

  @Post(':id/share-link')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Issue signed share link for a pollution site' })
  @ApiOkResponse({ type: SiteShareLinkResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  issueShareLink(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: SiteShareLinkRequestDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.engagementActions.issueShareLink(id, dto, user);
  }

  @Post(':id/feed-feedback')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 180, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit feed relevance feedback for a site' })
  @ApiOkResponse({ description: 'Feedback recorded' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  submitFeedFeedback(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: SubmitFeedFeedbackDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesFeed.submitFeedFeedback(id, dto, user);
  }
}

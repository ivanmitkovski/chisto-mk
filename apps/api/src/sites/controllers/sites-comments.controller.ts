import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../../auth/guards/optional-jwt-auth.guard';
import { ListSiteCommentsQueryDto } from '../dto/list-site-comments-query.dto';
import { CreateSiteCommentDto } from '../dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from '../dto/update-site-comment.dto';
import { SiteCommentLikeResponseDto } from '../dto/site-comment-like-response.dto';
import {
  SiteCommentTreeNodeResponseDto,
  SiteCommentsListResponseDto,
} from '../dto/site-comment-tree-response.dto';
import { SiteCommentsService } from '../services/site-comments.service';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesCommentsController {
  constructor(private readonly siteComments: SiteCommentsService) {}

  @Get(':id/comments')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get comments for site' })
  @ApiOkResponse({ description: 'Site comments fetched successfully', type: SiteCommentsListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findComments(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteCommentsQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.siteComments.findSiteComments(id, query, user);
  }

  @Idempotent('sites_sites-comments_53')
  @Post(':id/comments')
  @Idempotent('site_comment_create')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create comment for site' })
  @ApiCreatedResponse({ description: 'Site comment created successfully', type: SiteCommentTreeNodeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiBadRequestResponse({ description: 'Empty body or invalid parent' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  createComment(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: CreateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.siteComments.createSiteComment(id, dto, user);
  }

  @Idempotent('sites_sites-comments_71')
  @Post(':id/comments/:commentId/like')
  @Idempotent('site_comment_like')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Like a site comment' })
  @ApiOkResponse({ description: 'Like applied', type: SiteCommentLikeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  likeComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.siteComments.likeSiteComment(id, commentId, user);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete(':id/comments/:commentId/like')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unlike a site comment' })
  @ApiOkResponse({ description: 'Like removed', type: SiteCommentLikeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  unlikeComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.siteComments.unlikeSiteComment(id, commentId, user);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Edit a site comment' })
  @ApiOkResponse({ description: 'Comment updated', type: SiteCommentTreeNodeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Not the author' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  @ApiBadRequestResponse({ description: 'Empty body' })
  editComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @Body() dto: UpdateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.siteComments.updateSiteComment(id, commentId, dto, user);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a site comment' })
  @ApiOkResponse({ description: 'Comment soft-deleted' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Not the author' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  deleteComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.siteComments.deleteSiteComment(id, commentId, user);
  }
}

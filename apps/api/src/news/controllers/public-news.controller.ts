import { Controller, Get, Header, Param, Query, Res, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import type { Response } from 'express';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { ListNewsPostsQueryDto } from '../dto/news.dto';
import { NewsPostsQueryService } from '../services/news-posts-query.service';

@ApiTags('news')
@ApiStandardHttpErrorResponses()
@Controller('news')
@UseGuards(ThrottlerGuard)
export class PublicNewsController {
  constructor(private readonly query: NewsPostsQueryService) {}

  /**
   * Stable media URL for landing/ISR HTML. Redirects to a freshly signed S3 GET URL
   * so cached pages never embed expiring signatures (fixes intermittent broken covers).
   */
  @Get('media/:id')
  @Throttle({ default: { ttl: 60_000, limit: 300 } })
  @ApiOperation({ summary: 'Redirect to a freshly signed URL for published news media' })
  @ApiResponse({
    status: 302,
    description: 'Redirect to a short-lived signed S3 GET URL (Location header)',
  })
  @ApiResponse({ status: 404, description: 'Media not found or post is not published' })
  async mediaRedirect(@Param('id') id: string, @Res() res: Response): Promise<void> {
    const signed = await this.query.getPublishedMediaSignedUrl(id);
    const maxAge = this.query.getMediaRedirectMaxAgeSeconds();
    // Cap redirect caching under the signed-URL TTL so a cached Location never outlives S3 auth.
    res.setHeader(
      'Cache-Control',
      maxAge > 0
        ? `public, max-age=${maxAge}, stale-while-revalidate=${Math.min(60, maxAge)}`
        : 'private, no-store',
    );
    res.redirect(302, signed);
  }

  @Get('posts')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @Header('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400')
  @ApiOperation({ summary: 'List published news posts for a locale' })
  list(@Query() query: ListNewsPostsQueryDto, @Res({ passthrough: true }) res: Response) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listPublished(query.locale ?? 'en', query.limit ?? 50, query.offset ?? 0, query.category);
  }

  @Get('slugs')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'List published news slugs for sitemap' })
  slugs(@Res({ passthrough: true }) res: Response) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listPublishedSlugs();
  }

  @Get('slug-dates')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Published news slugs with last modified dates for sitemap' })
  slugDates(@Res({ passthrough: true }) res: Response) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listPublishedSlugDates();
  }

  @Get('posts/:slug/related')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Related published news posts' })
  related(
    @Param('slug') slug: string,
    @Query('locale') locale: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listRelated(locale ?? 'en', slug);
  }

  @Get('posts/:slug')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Get a published news post by slug' })
  getBySlug(
    @Param('slug') slug: string,
    @Query('locale') locale: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.getPublishedBySlug(locale ?? 'en', slug);
  }
}

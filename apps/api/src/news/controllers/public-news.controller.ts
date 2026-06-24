import { Controller, Get, Header, Param, Query, Res, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
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

  @Get('posts')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @Header('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400')
  @ApiOperation({ summary: 'List published news posts for a locale' })
  list(@Query() query: ListNewsPostsQueryDto, @Res({ passthrough: true }) res: Response) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listPublished(query.locale ?? 'en', query.limit ?? 50, query.offset ?? 0);
  }

  @Get('slugs')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'List published news slugs for sitemap' })
  slugs(@Res({ passthrough: true }) res: Response) {
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400');
    return this.query.listPublishedSlugs();
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

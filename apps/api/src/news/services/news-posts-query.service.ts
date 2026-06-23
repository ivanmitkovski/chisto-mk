import { Injectable, NotFoundException } from '@nestjs/common';
import type { NewsPostStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { NewsLocale } from '../types/news.types';
import { NEWS_LOCALES } from '../types/news.types';
import { toPublicDto, toPublicListItem } from './news-posts.mapper';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';

@Injectable()
export class NewsPostsQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
  ) {}

  normalizeLocale(locale: string): NewsLocale {
    const lower = locale.toLowerCase();
    if ((NEWS_LOCALES as readonly string[]).includes(lower)) {
      return lower as NewsLocale;
    }
    return 'mk';
  }

  private publishedWhere(now = new Date()) {
    const statuses: NewsPostStatus[] = ['PUBLISHED', 'SCHEDULED'];
    return {
      status: { in: statuses },
      publishedAt: { lte: now, not: null },
    };
  }

  async listPublished(locale: string, limit = 50, offset = 0) {
    const loc = this.normalizeLocale(locale);
    const now = new Date();
    const rows = await this.prisma.newsPost.findMany({
      where: this.publishedWhere(now),
      orderBy: { publishedAt: 'desc' },
      take: Math.min(limit, 100),
      skip: offset,
      include: { coverMedia: true },
    });

    const items = [];
    for (const row of rows) {
      const keys = row.coverMedia ? [row.coverMedia.objectKey] : [];
      const signed = await this.signedUrls.signMany(keys);
      items.push(toPublicListItem(row, loc, signed));
    }
    return { items, total: items.length };
  }

  async getPublishedBySlug(locale: string, slug: string) {
    const loc = this.normalizeLocale(locale);
    const now = new Date();
    const row = await this.prisma.newsPost.findFirst({
      where: { slug, ...this.publishedWhere(now) },
      include: {
        media: { orderBy: { sortOrder: 'asc' } },
        coverMedia: true,
      },
    });
    if (!row) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }
    const keys: string[] = row.media.map((m) => m.objectKey);
    if (row.coverMedia) keys.push(row.coverMedia.objectKey);
    const signed = await this.signedUrls.signMany(keys);
    return toPublicDto(row, loc, signed);
  }

  async listPublishedSlugs(): Promise<string[]> {
    const now = new Date();
    const rows = await this.prisma.newsPost.findMany({
      where: this.publishedWhere(now),
      select: { slug: true },
      orderBy: { publishedAt: 'desc' },
    });
    return rows.map((r) => r.slug);
  }
}

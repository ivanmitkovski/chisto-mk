import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { NewsLocale } from '../types/news.types';
import { NEWS_LOCALES } from '../types/news.types';
import { toPublicDto, toPublicListItem, categoryFromApi } from './news-posts.mapper';
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
    return 'en';
  }

  private publishedWhere(now = new Date()) {
    return {
      status: 'PUBLISHED' as const,
      publishedAt: { lte: now, not: null },
    };
  }

  async listPublished(locale: string, limit = 50, offset = 0, category?: string) {
    const loc = this.normalizeLocale(locale);
    const now = new Date();
    const where = {
      ...this.publishedWhere(now),
      ...(category ? { category: categoryFromApi(category as Parameters<typeof categoryFromApi>[0]) } : {}),
    };
    const [rows, total] = await Promise.all([
      this.prisma.newsPost.findMany({
        where,
        orderBy: [{ featured: 'desc' }, { publishedAt: 'desc' }],
        take: Math.min(limit, 100),
        skip: offset,
        include: { coverMedia: true },
      }),
      this.prisma.newsPost.count({ where }),
    ]);

    const items = [];
    for (const row of rows) {
      const keys = row.coverMedia ? [row.coverMedia.objectKey] : [];
      const signed = await this.signedUrls.signMany(keys);
      items.push(toPublicListItem(row, loc, signed));
    }
    return { items, total };
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

  async listPublishedSlugDates(): Promise<Array<{ slug: string; updatedAt: string; publishedAt: string }>> {
    const now = new Date();
    const rows = await this.prisma.newsPost.findMany({
      where: this.publishedWhere(now),
      select: { slug: true, updatedAt: true, publishedAt: true },
      orderBy: { publishedAt: 'desc' },
    });
    return rows.map((r) => ({
      slug: r.slug,
      updatedAt: r.updatedAt.toISOString(),
      publishedAt: r.publishedAt!.toISOString(),
    }));
  }

  async listRelated(locale: string, slug: string, limit = 3) {
    const loc = this.normalizeLocale(locale);
    const now = new Date();
    const post = await this.prisma.newsPost.findFirst({
      where: { slug, ...this.publishedWhere(now) },
    });
    if (!post) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const rows = await this.prisma.newsPost.findMany({
      where: {
        ...this.publishedWhere(now),
        category: post.category,
        slug: { not: slug },
      },
      orderBy: { publishedAt: 'desc' },
      take: Math.min(limit, 10),
      include: { coverMedia: true },
    });

    const items = [];
    for (const row of rows) {
      const keys = row.coverMedia ? [row.coverMedia.objectKey] : [];
      const signed = await this.signedUrls.signMany(keys);
      items.push(toPublicListItem(row, loc, signed));
    }
    return { items };
  }
}

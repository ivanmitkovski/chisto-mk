import { Injectable } from '@nestjs/common';
import type { NewsPostStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { Prisma } from '../../prisma-client';
import type { NewsCategoryApi, NewsPostStatusApi } from '../types/news.types';
import { categoryFromApi, toAdminDto } from './news-posts.mapper';
import { NEWS_POST_ADMIN_INCLUDE, signNewsPostMedia } from './news-posts-signing';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { htmlBlockHasContent } from '@chisto/news-content';
import { NEWS_LOCALES, type NewsTranslations } from '../types/news.types';
import { paragraphHasContent } from './news-content-sanitize.service';

export type AdminListNewsQuery = {
  status?: NewsPostStatusApi;
  category?: NewsCategoryApi;
  q?: string;
  limit?: number;
  offset?: number;
  sort?: 'publishedAt' | 'updatedAt' | 'title';
};

function statusFromApi(status: NewsPostStatusApi): NewsPostStatus {
  const map: Record<NewsPostStatusApi, NewsPostStatus> = {
    draft: 'DRAFT',
    scheduled: 'SCHEDULED',
    published: 'PUBLISHED',
    archived: 'ARCHIVED',
  };
  return map[status];
}

function localeCompleteForLocale(
  translations: NewsTranslations,
  locale: (typeof NEWS_LOCALES)[number],
  hasCover: boolean,
): boolean {
  const entry = translations[locale];
  if (!entry.title.trim() || !entry.excerpt.trim() || !entry.body.length) return false;
  for (const block of entry.body) {
    if (block.type === 'paragraph' && !paragraphHasContent(block)) return false;
    if (block.type === 'html' && !htmlBlockHasContent(block.html ?? '')) return false;
    if (block.type === 'heading' && !block.text.trim()) return false;
    if (block.type === 'list' && !block.items.some((item) => item.trim())) return false;
    if ((block.type === 'image' || block.type === 'video') && !block.mediaId?.trim()) return false;
  }
  return hasCover;
}

@Injectable()
export class NewsPostsAdminQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
  ) {}

  async list(query: AdminListNewsQuery = {}) {
    const limit = Math.min(Math.max(query.limit ?? 20, 1), 100);
    const offset = Math.max(query.offset ?? 0, 0);
    const where: Prisma.NewsPostWhereInput = {};

    if (query.status) {
      where.status = statusFromApi(query.status);
    }
    if (query.category) {
      where.category = categoryFromApi(query.category);
    }
    if (query.q?.trim()) {
      const q = query.q.trim();
      where.OR = [
        { slug: { contains: q, mode: 'insensitive' } },
        ...NEWS_LOCALES.map((locale) => ({
          translations: { path: [locale, 'title'], string_contains: q },
        })),
      ];
    }

    const orderBy: Prisma.NewsPostOrderByWithRelationInput[] =
      query.sort === 'updatedAt'
        ? [{ updatedAt: 'desc' }]
        : query.sort === 'title'
          ? [{ slug: 'asc' }]
          : [{ publishedAt: 'desc' }, { createdAt: 'desc' }];

    const [rows, total, statusGroups] = await Promise.all([
      this.prisma.newsPost.findMany({
        where,
        orderBy,
        take: limit,
        skip: offset,
        include: NEWS_POST_ADMIN_INCLUDE,
      }),
      this.prisma.newsPost.count({ where }),
      this.prisma.newsPost.groupBy({
        by: ['status'],
        where,
        _count: { _all: true },
      }),
    ]);

    const countsByStatus: Record<string, number> = {};
    for (const g of statusGroups) {
      countsByStatus[g.status.toLowerCase()] = g._count._all;
    }

    const items = [];
    for (const row of rows) {
      const signed = await signNewsPostMedia(this.signedUrls, row);
      const dto = toAdminDto(row, signed);
      const translations = dto.translations;
      items.push({
        ...dto,
        localeCompleteness: {
          en: localeCompleteForLocale(translations, 'en', Boolean(row.coverMediaId)),
          mk: localeCompleteForLocale(translations, 'mk', Boolean(row.coverMediaId)),
          sq: localeCompleteForLocale(translations, 'sq', Boolean(row.coverMediaId)),
        },
        createdById: row.createdById,
        updatedById: row.updatedById,
        featured: row.featured,
      });
    }

    return { items, total, countsByStatus, limit, offset };
  }
}

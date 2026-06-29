import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import type { Prisma } from '../../prisma-client';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import type { NewsCategoryApi, NewsTranslations } from '../types/news.types';
import { categoryToApi, categoryFromApi, parseTranslations } from './news-posts.mapper';
import { NEWS_POST_ADMIN_INCLUDE } from './news-posts-signing';
import { assertMediaIntegrity, assertValidSlug, assertValidTranslations, normalizeSlug } from './news-posts-validation';
import { normalizeTranslationsBody } from './news-content-sanitize.service';
import { NewsRevalidateService } from './news-revalidate.service';

const MAX_REVISIONS_PER_POST = 10;

export const NEWS_REVISIONS_MAX_PER_POST = MAX_REVISIONS_PER_POST;

export type NewsRevisionSnapshot = {
  slug: string;
  category: NewsCategoryApi;
  featured: boolean;
  scheduledAt: string | null;
  translations: NewsTranslations;
};

@Injectable()
export class NewsRevisionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly revalidate: NewsRevalidateService,
    private readonly audit?: AuditService,
  ) {}

  private snapshotFromPost(post: {
    slug: string;
    category: Parameters<typeof categoryToApi>[0];
    featured: boolean;
    scheduledAt: Date | null;
    translations: unknown;
  }): NewsRevisionSnapshot {
    return {
      slug: post.slug,
      category: categoryToApi(post.category),
      featured: post.featured,
      scheduledAt: post.scheduledAt?.toISOString() ?? null,
      translations: parseTranslations(post.translations),
    };
  }

  async createRevision(postId: string, actor?: AuthenticatedUser): Promise<void> {
    const post = await this.prisma.newsPost.findUnique({ where: { id: postId } });
    if (!post) return;

    const snapshot = this.snapshotFromPost(post);
    await this.prisma.newsPostRevision.create({
      data: {
        postId,
        snapshot: snapshot as unknown as Prisma.InputJsonValue,
        createdById: actor?.userId ?? null,
      },
    });

    const excess = await this.prisma.newsPostRevision.findMany({
      where: { postId },
      orderBy: { createdAt: 'desc' },
      skip: MAX_REVISIONS_PER_POST,
      select: { id: true },
    });
    if (excess.length > 0) {
      await this.prisma.newsPostRevision.deleteMany({
        where: { id: { in: excess.map((r) => r.id) } },
      });
    }
  }

  async list(postId: string) {
    const post = await this.prisma.newsPost.findUnique({ where: { id: postId }, select: { id: true } });
    if (!post) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const rows = await this.prisma.newsPostRevision.findMany({
      where: { postId },
      orderBy: { createdAt: 'desc' },
      take: MAX_REVISIONS_PER_POST,
    });
    return rows.map((row) => ({
      id: row.id,
      createdAt: row.createdAt.toISOString(),
      createdById: row.createdById,
      snapshot: row.snapshot as NewsRevisionSnapshot,
    }));
  }

  async restore(postId: string, revisionId: string, actor?: AuthenticatedUser) {
    const revision = await this.prisma.newsPostRevision.findFirst({
      where: { id: revisionId, postId },
    });
    if (!revision) {
      throw new NotFoundException({
        code: 'NEWS_REVISION_NOT_FOUND',
        message: 'Revision not found',
      });
    }

    const snapshot = revision.snapshot as NewsRevisionSnapshot;
    const existing = await this.prisma.newsPost.findUnique({ where: { id: postId } });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    if (existing.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be modified',
      });
    }

    const publishable = existing.status === 'PUBLISHED' || existing.status === 'SCHEDULED';

    if (existing.status === 'PUBLISHED' && snapshot.slug !== existing.slug) {
      throw new BadRequestException({
        code: 'NEWS_SLUG_IMMUTABLE',
        message: 'Slug cannot be changed after publication',
      });
    }

    const normalizedSlug = normalizeSlug(snapshot.slug);
    assertValidSlug(normalizedSlug);
    if (normalizedSlug !== existing.slug) {
      const taken = await this.prisma.newsPost.findUnique({ where: { slug: normalizedSlug } });
      if (taken && taken.id !== postId) {
        throw new BadRequestException({
          code: 'NEWS_SLUG_TAKEN',
          message: 'A post with this slug already exists',
        });
      }
    }

    if (publishable) {
      const normalized = normalizeTranslationsBody(snapshot.translations);
      assertValidTranslations(normalized, true);
      const withMedia = await this.prisma.newsPost.findUnique({
        where: { id: postId },
        include: { media: true },
      });
      assertMediaIntegrity(
        normalized,
        withMedia?.media ?? [],
        withMedia?.coverMediaId ?? null,
        { requireCover: false },
      );
    }

    const restoredTranslations = normalizeTranslationsBody(snapshot.translations);

    await this.createRevision(postId, actor);

    const row = await this.prisma.$transaction(async (tx) => {
      if (snapshot.featured) {
        await tx.newsPost.updateMany({
          where: { id: { not: postId }, featured: true },
          data: { featured: false },
        });
      }
      return tx.newsPost.update({
        where: { id: postId },
        data: {
          slug: normalizedSlug,
          category: categoryFromApi(snapshot.category),
          featured: snapshot.featured,
          scheduledAt: snapshot.scheduledAt ? new Date(snapshot.scheduledAt) : null,
          status:
            existing.status === 'SCHEDULED' && !snapshot.scheduledAt
              ? 'DRAFT'
              : existing.status === 'DRAFT' && snapshot.scheduledAt
                ? 'SCHEDULED'
                : existing.status,
          translations: restoredTranslations as unknown as Prisma.InputJsonValue,
          updatedById: actor?.userId ?? null,
        },
        include: NEWS_POST_ADMIN_INCLUDE,
      });
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.restore',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug, revisionId },
    });

    if (publishable) {
      void this.revalidate.triggerLandingRevalidate();
    }

    return row;
  }

  async clearHistory(postId: string, actor?: AuthenticatedUser): Promise<{ deleted: number }> {
    const post = await this.prisma.newsPost.findUnique({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const result = await this.prisma.newsPostRevision.deleteMany({ where: { postId } });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.revisions_clear',
      resourceType: 'NewsPost',
      resourceId: postId,
      metadata: { slug: post.slug, deleted: result.count },
    });

    return { deleted: result.count };
  }
}

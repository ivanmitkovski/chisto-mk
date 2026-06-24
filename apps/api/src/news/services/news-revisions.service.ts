import { Injectable, NotFoundException } from '@nestjs/common';
import type { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import type { NewsCategoryApi, NewsTranslations } from '../types/news.types';
import { categoryToApi, categoryFromApi, parseTranslations } from './news-posts.mapper';

const MAX_REVISIONS_PER_POST = 20;

export type NewsRevisionSnapshot = {
  slug: string;
  category: NewsCategoryApi;
  featured: boolean;
  scheduledAt: string | null;
  translations: NewsTranslations;
};

@Injectable()
export class NewsRevisionsService {
  constructor(private readonly prisma: PrismaService) {}

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

    await this.createRevision(postId, actor);

    return this.prisma.newsPost.update({
      where: { id: postId },
      data: {
        slug: snapshot.slug,
        category: categoryFromApi(snapshot.category),
        featured: snapshot.featured,
        scheduledAt: snapshot.scheduledAt ? new Date(snapshot.scheduledAt) : null,
        translations: snapshot.translations as unknown as Prisma.InputJsonValue,
        updatedById: actor?.userId ?? null,
      },
    });
  }
}

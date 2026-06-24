import { Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import type { NewsTranslations } from '../types/news.types';
import { toAdminDto } from './news-posts.mapper';
import { NEWS_POST_ADMIN_INCLUDE, signNewsPostMedia } from './news-posts-signing';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { NewsRevalidateService } from './news-revalidate.service';
import { assertValidTranslations, assertMediaIntegrity } from './news-posts-validation';

@Injectable()
export class NewsPostsLifecycleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
    private readonly audit?: AuditService,
  ) {}

  async publish(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({
      where: { id },
      include: NEWS_POST_ADMIN_INCLUDE,
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const translations = existing.translations as NewsTranslations;
    assertValidTranslations(translations, true);

    const mediaIds = new Set(existing.media.map((m) => m.id));
    assertMediaIntegrity(translations, mediaIds, Boolean(existing.coverMediaId));

    const now = new Date();
    const publishedAt =
      existing.scheduledAt && existing.scheduledAt > now ? existing.scheduledAt : now;
    const status = existing.scheduledAt && existing.scheduledAt > now ? 'SCHEDULED' : 'PUBLISHED';

    const row = await this.prisma.newsPost.update({
      where: { id },
      data: {
        status,
        publishedAt,
        updatedById: actor?.userId ?? null,
      },
      include: NEWS_POST_ADMIN_INCLUDE,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.publish',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug, status },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }

  async unpublish(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const row = await this.prisma.newsPost.update({
      where: { id },
      data: {
        status: 'DRAFT',
        publishedAt: null,
        scheduledAt: null,
        updatedById: actor?.userId ?? null,
      },
      include: NEWS_POST_ADMIN_INCLUDE,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.unpublish',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }

  async archive(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const row = await this.prisma.newsPost.update({
      where: { id },
      data: { status: 'ARCHIVED', updatedById: actor?.userId ?? null },
      include: NEWS_POST_ADMIN_INCLUDE,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.archive',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }
}

import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { toAdminDto, parseTranslations } from './news-posts.mapper';
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

    if (existing.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be published',
      });
    }

    const translations = parseTranslations(existing.translations);
    assertValidTranslations(translations, true);

    assertMediaIntegrity(translations, existing.media, existing.coverMediaId, {
      requireAltText: true,
    });

    const now = new Date();
    const isFutureSchedule = Boolean(existing.scheduledAt && existing.scheduledAt > now);

    // Already live: re-validate, audit update_publish, revalidate cache; preserve publishedAt.
    if (existing.status === 'PUBLISHED' && !isFutureSchedule) {
      const row = await this.prisma.newsPost.update({
        where: { id },
        data: {
          updatedById: actor?.userId ?? null,
        },
        include: NEWS_POST_ADMIN_INCLUDE,
      });

      await this.audit?.log({
        actorId: actor?.userId ?? null,
        action: 'news.post.update_publish',
        resourceType: 'NewsPost',
        resourceId: row.id,
        metadata: { slug: row.slug, status: row.status },
      });

      void this.revalidate.triggerLandingRevalidate();

      const signed = await signNewsPostMedia(this.signedUrls, row);
      return toAdminDto(row, signed);
    }

    const row = await this.prisma.newsPost.update({
      where: { id },
      data: {
        status: isFutureSchedule ? 'SCHEDULED' : 'PUBLISHED',
        publishedAt: isFutureSchedule ? null : now,
        scheduledAt: isFutureSchedule ? existing.scheduledAt : null,
        updatedById: actor?.userId ?? null,
      },
      include: NEWS_POST_ADMIN_INCLUDE,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.publish',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug, status: row.status },
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

    if (existing.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be unpublished',
      });
    }

    if (existing.status === 'DRAFT') {
      const row = await this.prisma.newsPost.findUnique({
        where: { id },
        include: NEWS_POST_ADMIN_INCLUDE,
      });
      const signed = await signNewsPostMedia(this.signedUrls, row!);
      return toAdminDto(row!, signed);
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

    if (existing.status === 'ARCHIVED') {
      const row = await this.prisma.newsPost.findUnique({
        where: { id },
        include: NEWS_POST_ADMIN_INCLUDE,
      });
      const signed = await signNewsPostMedia(this.signedUrls, row!);
      return toAdminDto(row!, signed);
    }

    const row = await this.prisma.newsPost.update({
      where: { id },
      data: {
        status: 'ARCHIVED',
        publishedAt: null,
        scheduledAt: null,
        featured: false,
        updatedById: actor?.userId ?? null,
      },
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

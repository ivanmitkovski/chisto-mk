import { Prisma } from '../../prisma-client';
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditService } from '../../audit/services/audit.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { PrismaService } from '../../prisma/prisma.service';
import type { NewsCategoryApi, NewsTranslations } from '../types/news.types';
import { categoryFromApi, toAdminDto, parseTranslations } from './news-posts.mapper';
import { NEWS_POST_ADMIN_INCLUDE, signNewsPostMedia } from './news-posts-signing';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { NewsRevalidateService } from './news-revalidate.service';
import { NewsRevisionsService } from './news-revisions.service';
import {
  assertValidCategory,
  assertValidSlug,
  assertValidTranslations,
  assertScheduledAtNotInPast,
  assertMediaIntegrity,
  normalizeSlug,
} from './news-posts-validation';
import { normalizeTranslationsBody } from './news-content-sanitize.service';

export type UpdateNewsPostInput = {
  slug?: string;
  category?: NewsCategoryApi;
  translations?: NewsTranslations;
  scheduledAt?: string | null;
  featured?: boolean;
  /** When set, reject with 409 if the post was modified since this timestamp. */
  expectedUpdatedAt?: string;
};

@Injectable()
export class NewsPostsUpdateService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
    private readonly revisions: NewsRevisionsService,
    private readonly audit?: AuditService,
  ) {}

  async update(id: string, input: UpdateNewsPostInput, actor?: AuthenticatedUser) {
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
        message: 'Archived posts cannot be modified',
      });
    }

    if (input.expectedUpdatedAt) {
      const expectedMs = Date.parse(input.expectedUpdatedAt);
      if (Number.isNaN(expectedMs) || existing.updatedAt.getTime() !== expectedMs) {
        throw new ConflictException({
          code: 'NEWS_POST_CONFLICT',
          message: 'News post was modified by another editor',
        });
      }
    }

    if (existing.status === 'PUBLISHED' && input.slug && input.slug !== existing.slug) {
      throw new BadRequestException({
        code: 'NEWS_SLUG_IMMUTABLE',
        message: 'Slug cannot be changed after publication',
      });
    }

    const data: Prisma.NewsPostUpdateInput = { updatedById: actor?.userId ?? null };

    if (input.category) {
      assertValidCategory(input.category);
      data.category = categoryFromApi(input.category);
    }
    const isLive = existing.status === 'PUBLISHED' || existing.status === 'SCHEDULED';
    if (input.translations) {
      const translations = normalizeTranslationsBody(input.translations);
      assertValidTranslations(translations, isLive);
      data.translations = translations as unknown as Prisma.InputJsonValue;
      if (isLive) {
        const withMedia = await this.prisma.newsPost.findUnique({
          where: { id },
          include: { media: true },
        });
        assertMediaIntegrity(
          translations,
          withMedia?.media ?? [],
          withMedia?.coverMediaId ?? null,
          { requireCover: true, requireAltText: true },
        );
      }
    }
    if (input.slug) {
      const slug = normalizeSlug(input.slug);
      assertValidSlug(slug);
      if (slug !== existing.slug) {
        const taken = await this.prisma.newsPost.findUnique({ where: { slug } });
        if (taken) {
          throw new BadRequestException({
            code: 'NEWS_SLUG_TAKEN',
            message: 'A post with this slug already exists',
          });
        }
        data.slug = slug;
      }
    }
    if (input.scheduledAt !== undefined) {
      if (existing.status === 'PUBLISHED') {
        throw new BadRequestException({
          code: 'NEWS_SCHEDULE_NOT_ALLOWED',
          message: 'Cannot change schedule on a published post; unpublish first',
        });
      }
      if (input.scheduledAt) {
        assertScheduledAtNotInPast(input.scheduledAt);
      }
      data.scheduledAt = input.scheduledAt ? new Date(input.scheduledAt) : null;
      if (input.scheduledAt && existing.status === 'DRAFT') {
        const translations =
          input.translations ?? parseTranslations(existing.translations);
        assertValidTranslations(translations, true);
        const withMedia = await this.prisma.newsPost.findUnique({
          where: { id },
          include: { media: true },
        });
        assertMediaIntegrity(
          translations,
          withMedia?.media ?? [],
          withMedia?.coverMediaId ?? null,
          { requireCover: true, requireAltText: true },
        );
        data.status = 'SCHEDULED';
      } else if (!input.scheduledAt && existing.status === 'SCHEDULED') {
        data.status = 'DRAFT';
      }
    }
    if (input.featured !== undefined) {
      data.featured = input.featured;
    }

    await this.revisions.createRevision(id, actor);

    let row;
    try {
      row = await this.prisma.$transaction(async (tx) => {
        if (input.featured === true) {
          await tx.newsPost.updateMany({
            where: { id: { not: id }, featured: true },
            data: { featured: false },
          });
        }
        return tx.newsPost.update({
          where: { id },
          data,
          include: NEWS_POST_ADMIN_INCLUDE,
        });
      });
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new BadRequestException({
          code: 'NEWS_SLUG_TAKEN',
          message: 'A post with this slug already exists',
        });
      }
      throw err;
    }

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.update',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    if (row.status === 'PUBLISHED' || row.status === 'SCHEDULED') {
      void this.revalidate.triggerLandingRevalidate();
    }

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }
}

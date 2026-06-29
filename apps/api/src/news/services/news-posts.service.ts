import { Prisma } from '../../prisma-client';
import {
  BadRequestException,
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
import { NewsPostsDeleteService } from './news-posts-delete.service';
import { NewsPostsLifecycleService } from './news-posts-lifecycle.service';
import { NewsRevisionsService } from './news-revisions.service';
import {
  assertValidCategory,
  assertValidSlug,
  assertValidTranslations,
  assertScheduledAtNotInPast,
  assertMediaIntegrity,
  normalizeSlug,
  stripMediaFromTranslations,
} from './news-posts-validation';
import { normalizeTranslationsBody } from './news-content-sanitize.service';

export type CreateNewsPostInput = {
  slug?: string;
  category: NewsCategoryApi;
  translations: NewsTranslations;
};

export type UpdateNewsPostInput = {
  slug?: string;
  category?: NewsCategoryApi;
  translations?: NewsTranslations;
  scheduledAt?: string | null;
  featured?: boolean;
};

@Injectable()
export class NewsPostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
    private readonly deleteService: NewsPostsDeleteService,
    private readonly lifecycle: NewsPostsLifecycleService,
    private readonly revisions: NewsRevisionsService,
    private readonly audit?: AuditService,
  ) {}

  async list() {
    const rows = await this.prisma.newsPost.findMany({
      orderBy: [{ publishedAt: 'desc' }, { createdAt: 'desc' }],
      include: NEWS_POST_ADMIN_INCLUDE,
    });
    const result = [];
    for (const row of rows) {
      const signed = await signNewsPostMedia(this.signedUrls, row);
      result.push(toAdminDto(row, signed));
    }
    return result;
  }

  async getById(id: string) {
    const row = await this.prisma.newsPost.findUnique({
      where: { id },
      include: NEWS_POST_ADMIN_INCLUDE,
    });
    if (!row) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }
    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }

  async create(input: CreateNewsPostInput, actor?: AuthenticatedUser) {
    assertValidCategory(input.category);
    const translations = normalizeTranslationsBody(input.translations);
    assertValidTranslations(translations, false);
    const slug = normalizeSlug(input.slug ?? translations.en.title);
    assertValidSlug(slug);

    const existing = await this.prisma.newsPost.findUnique({ where: { slug } });
    if (existing) {
      throw new BadRequestException({
        code: 'NEWS_SLUG_TAKEN',
        message: 'A post with this slug already exists',
      });
    }

    const row = await this.createPostRow(slug, input, translations, actor);

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.create',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }

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
          { requireCover: false },
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

  publish(id: string, actor?: AuthenticatedUser) {
    return this.lifecycle.publish(id, actor);
  }

  unpublish(id: string, actor?: AuthenticatedUser) {
    return this.lifecycle.unpublish(id, actor);
  }

  archive(id: string, actor?: AuthenticatedUser) {
    return this.lifecycle.archive(id, actor);
  }

  delete(id: string, actor?: AuthenticatedUser) {
    return this.deleteService.delete(id, actor);
  }

  async duplicate(id: string, actor?: AuthenticatedUser) {
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

    const translations = stripMediaFromTranslations(parseTranslations(existing.translations));
    let suffix = 1;
    let slug = `${existing.slug}-copy`;
    while (await this.prisma.newsPost.findUnique({ where: { slug } })) {
      suffix += 1;
      slug = `${existing.slug}-copy-${suffix}`;
    }

    const row = await this.prisma.newsPost.create({
      data: {
        slug,
        category: existing.category,
        status: 'DRAFT',
        translations: translations as unknown as Prisma.InputJsonValue,
        featured: false,
        createdById: actor?.userId ?? null,
        updatedById: actor?.userId ?? null,
      },
      include: NEWS_POST_ADMIN_INCLUDE,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.duplicate',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { sourceId: id, slug: row.slug },
    });

    const signed = await signNewsPostMedia(this.signedUrls, row);
    return toAdminDto(row, signed);
  }

  async restoreRevision(id: string, revisionId: string, actor?: AuthenticatedUser) {
    await this.revisions.restore(id, revisionId, actor);
    return this.getById(id);
  }

  listRevisions(postId: string) {
    return this.revisions.list(postId);
  }

  clearRevisionHistory(id: string, actor?: AuthenticatedUser) {
    return this.revisions.clearHistory(id, actor);
  }

  private async createPostRow(
    slug: string,
    input: CreateNewsPostInput,
    translations: NewsTranslations,
    actor?: AuthenticatedUser,
  ) {
    try {
      return await this.prisma.newsPost.create({
        data: {
          slug,
          category: categoryFromApi(input.category),
          status: 'DRAFT',
          translations: translations as unknown as Prisma.InputJsonValue,
          createdById: actor?.userId ?? null,
          updatedById: actor?.userId ?? null,
        },
        include: NEWS_POST_ADMIN_INCLUDE,
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
  }
}

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Prisma } from '../../prisma-client';
import { AuditService } from '../../audit/services/audit.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { PrismaService } from '../../prisma/prisma.service';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import type { NewsCategoryApi, NewsTranslations } from '../types/news.types';
import { categoryFromApi, toAdminDto } from './news-posts.mapper';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { NewsRevalidateService } from './news-revalidate.service';
import {
  assertValidCategory,
  assertValidSlug,
  assertValidTranslations,
  normalizeSlug,
} from './news-posts-validation';

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
};

@Injectable()
export class NewsPostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
    private readonly s3: S3StorageClient,
    private readonly audit?: AuditService,
  ) {}

  private postInclude = {
    media: { orderBy: { sortOrder: 'asc' as const } },
    coverMedia: true,
  };

  private async signPostMedia(
    post: Prisma.NewsPostGetPayload<{ include: { media: true; coverMedia: true } }>,
  ) {
    const keys: string[] = [];
    for (const m of post.media) keys.push(m.objectKey);
    if (post.coverMedia) keys.push(post.coverMedia.objectKey);
    return this.signedUrls.signMany(keys);
  }

  async list() {
    const rows = await this.prisma.newsPost.findMany({
      orderBy: [{ publishedAt: 'desc' }, { createdAt: 'desc' }],
      include: this.postInclude,
    });
    const result = [];
    for (const row of rows) {
      const signed = await this.signPostMedia(row);
      result.push(toAdminDto(row, signed));
    }
    return result;
  }

  async getById(id: string) {
    const row = await this.prisma.newsPost.findUnique({
      where: { id },
      include: this.postInclude,
    });
    if (!row) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }
    const signed = await this.signPostMedia(row);
    return toAdminDto(row, signed);
  }

  async create(input: CreateNewsPostInput, actor?: AuthenticatedUser) {
    assertValidCategory(input.category);
    assertValidTranslations(input.translations, false);
    const slug = normalizeSlug(input.slug ?? input.translations.en.title);
    assertValidSlug(slug);

    const existing = await this.prisma.newsPost.findUnique({ where: { slug } });
    if (existing) {
      throw new BadRequestException({
        code: 'NEWS_SLUG_TAKEN',
        message: 'A post with this slug already exists',
      });
    }

    const row = await this.prisma.newsPost.create({
      data: {
        slug,
        category: categoryFromApi(input.category),
        status: 'DRAFT',
        translations: input.translations as unknown as Prisma.InputJsonValue,
        createdById: actor?.userId ?? null,
        updatedById: actor?.userId ?? null,
      },
      include: this.postInclude,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.create',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    const signed = await this.signPostMedia(row);
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
    if (input.translations) {
      assertValidTranslations(input.translations, false);
      data.translations = input.translations as unknown as Prisma.InputJsonValue;
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
      data.scheduledAt = input.scheduledAt ? new Date(input.scheduledAt) : null;
      if (input.scheduledAt && existing.status === 'DRAFT') {
        data.status = 'SCHEDULED';
      }
    }

    const row = await this.prisma.newsPost.update({
      where: { id },
      data,
      include: this.postInclude,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.update',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    const signed = await this.signPostMedia(row);
    return toAdminDto(row, signed);
  }

  async publish(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({
      where: { id },
      include: this.postInclude,
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    const translations = existing.translations as NewsTranslations;
    assertValidTranslations(translations, true);

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
      include: this.postInclude,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.publish',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug, status },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await this.signPostMedia(row);
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
      include: this.postInclude,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.unpublish',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await this.signPostMedia(row);
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
      include: this.postInclude,
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.archive',
      resourceType: 'NewsPost',
      resourceId: row.id,
      metadata: { slug: row.slug },
    });

    void this.revalidate.triggerLandingRevalidate();

    const signed = await this.signPostMedia(row);
    return toAdminDto(row, signed);
  }

  async delete(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({
      where: { id },
      include: { media: true },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    for (const m of existing.media) {
      this.signedUrls.invalidateKey(m.objectKey);
      if (this.s3.enabled) {
        try {
        await this.s3.deleteObject(m.objectKey);
        } catch {
          // best effort
        }
      }
    }

    await this.prisma.newsPost.delete({ where: { id } });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.delete',
      resourceType: 'NewsPost',
      resourceId: id,
      metadata: { slug: existing.slug },
    });

    void this.revalidate.triggerLandingRevalidate();
  }
}

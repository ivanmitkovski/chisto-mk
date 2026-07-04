import { BadRequestException, Injectable, Logger, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { randomUUID } from 'crypto';
import { Prisma } from '../../prisma-client';
import type { NewsLocale, NewsTranslations } from '../types/news.types';
import { parseTranslations, toMediaDto } from './news-posts.mapper';
import { assertMediaIntegrity, stripMediaIdFromTranslations } from './news-posts-validation';
import { NewsImageProcessor } from './news-image-processor';
import {
  toNewsMediaPrismaKind,
  validateAndProcessNewsMediaFile,
  type NewsMediaUploadKind,
} from './news-media-upload-validation';

export type UploadNewsMediaInput = {
  postId: string;
  kind: NewsMediaUploadKind;
  file: { buffer: Buffer; mimetype: string; size: number; originalname: string };
  actor?: AuthenticatedUser;
};

@Injectable()
export class NewsMediaUploadService {
  private readonly logger = new Logger(NewsMediaUploadService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
    private readonly imageProcessor: NewsImageProcessor,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly audit?: AuditService,
  ) {}

  async upload(input: UploadNewsMediaInput) {
    const post = await this.prisma.newsPost.findUnique({
      where: { id: input.postId },
      include: { coverMedia: true },
    });
    if (!post) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    if (post.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be modified',
      });
    }

    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured',
      });
    }

    const prismaKind = toNewsMediaPrismaKind(input.kind);
    const processed = await validateAndProcessNewsMediaFile(
      this.imageProcessor,
      input.kind,
      input.file,
    );

    const subfolder = input.kind === 'cover' ? 'cover' : 'inline';
    const key = `news/${input.postId}/${subfolder}/${randomUUID()}.${processed.ext}`;

    try {
      await this.s3.putObject({
        Key: key,
        Body: processed.body,
        ContentType: processed.mime,
      });
    } catch (err) {
      this.logger.warn(`news.upload s3_put_failed key=${key} err=${(err as Error).message}`);
      throw new ServiceUnavailableException({
        code: 'NEWS_UPLOAD_STORAGE_ERROR',
        message: 'Could not store the file. Please try again shortly.',
      });
    }

    const media = await this.prisma.newsMedia.create({
      data: {
        postId: input.postId,
        kind: prismaKind,
        objectKey: key,
        mimeType: processed.mime,
        fileName: input.file.originalname?.slice(0, 255) ?? null,
        sizeBytes: processed.body.length,
        width: processed.width,
        height: processed.height,
        sortOrder: 0,
      },
    });

    try {
      if (input.kind === 'cover') {
        const previousCoverId = post.coverMediaId;
        const previousCover = post.coverMedia;
        await this.prisma.newsPost.update({
          where: { id: input.postId },
          data: { coverMediaId: media.id },
        });
        if (previousCoverId && previousCover) {
          await this.deleteMediaRecord(previousCover.id, previousCover.objectKey);
        }
      }
    } catch (err) {
      await this.prisma.newsMedia.delete({ where: { id: media.id } }).catch(() => undefined);
      if (this.s3.enabled) {
        await this.s3.deleteObject(key).catch(() => undefined);
      }
      throw err;
    }

    await this.audit?.log({
      actorId: input.actor?.userId ?? null,
      action: 'news.media.upload',
      resourceType: 'NewsMedia',
      resourceId: media.id,
      metadata: { postId: input.postId, kind: input.kind },
    });

    // Published posts: defer public cache refresh until explicit update-publish.
    // Scheduled posts are not public yet; no ISR refresh needed for media alone.

    const url = await this.signedUrls.getSignedGetUrl(key);
    return { ...media, url };
  }

  async deleteMedia(mediaId: string, actor?: AuthenticatedUser): Promise<void> {
    const media = await this.prisma.newsMedia.findUnique({
      where: { id: mediaId },
      include: { coverForPost: true, post: true },
    });
    if (!media) {
      throw new NotFoundException({
        code: 'NEWS_MEDIA_NOT_FOUND',
        message: 'News media not found',
      });
    }

    if (media.post.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be modified',
      });
    }

    const isLive = media.post.status === 'PUBLISHED' || media.post.status === 'SCHEDULED';
    if (isLive && media.coverForPost) {
      throw new BadRequestException({
        code: 'NEWS_MEDIA_IN_USE',
        message: 'Cover image cannot be deleted on a live post',
      });
    }

    await this.prisma.$transaction(async (tx) => {
      if (media.coverForPost) {
        await tx.newsPost.update({
          where: { id: media.coverForPost.id },
          data: { coverMediaId: null },
        });
      }

      if (isLive) {
        const translations = parseTranslations(media.post.translations) as NewsTranslations;
        const stripped = stripMediaIdFromTranslations(translations, mediaId);
        await tx.newsPost.update({
          where: { id: media.postId },
          data: {
            translations: stripped as unknown as Prisma.InputJsonValue,
          },
        });
      }

      await tx.newsMedia.delete({ where: { id: mediaId } });
    });

    this.signedUrls.invalidateKey(media.objectKey);
    if (this.s3.enabled) {
      try {
        await this.s3.deleteObject(media.objectKey);
      } catch (err) {
        this.logger.warn(`news.delete s3_failed key=${media.objectKey} err=${(err as Error).message}`);
      }
    }

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.media.delete',
      resourceType: 'NewsMedia',
      resourceId: mediaId,
      metadata: { postId: media.postId },
    });

    // Published: defer revalidate until update-publish (see upload).
  }

  async updateAltText(
    mediaId: string,
    altText: Partial<Record<NewsLocale, string>>,
    actor?: AuthenticatedUser,
  ) {
    const media = await this.prisma.newsMedia.findUnique({
      where: { id: mediaId },
      include: { post: true },
    });
    if (!media) {
      throw new NotFoundException({
        code: 'NEWS_MEDIA_NOT_FOUND',
        message: 'News media not found',
      });
    }

    if (media.post.status === 'ARCHIVED') {
      throw new BadRequestException({
        code: 'NEWS_POST_ARCHIVED',
        message: 'Archived posts cannot be modified',
      });
    }

    const current = (media.altText as Partial<Record<NewsLocale, string>> | null) ?? {};
    const merged: Partial<Record<NewsLocale, string>> = { ...current };
    for (const [locale, value] of Object.entries(altText)) {
      if (value === undefined) continue;
      const trimmed = value.trim();
      if (trimmed) {
        merged[locale as NewsLocale] = trimmed;
      } else {
        delete merged[locale as NewsLocale];
      }
    }

    const isLive = media.post.status === 'PUBLISHED' || media.post.status === 'SCHEDULED';
    if (isLive) {
      const postWithMedia = await this.prisma.newsPost.findUnique({
        where: { id: media.postId },
        include: { media: true },
      });
      if (postWithMedia) {
        const mediaForCheck = postWithMedia.media.map((m) =>
          m.id === mediaId
            ? { ...m, altText: Object.keys(merged).length > 0 ? merged : null }
            : m,
        );
        assertMediaIntegrity(
          parseTranslations(postWithMedia.translations) as NewsTranslations,
          mediaForCheck,
          postWithMedia.coverMediaId,
          { requireCover: true, requireAltText: true },
        );
      }
    }

    const updated = await this.prisma.newsMedia.update({
      where: { id: mediaId },
      data: {
        altText:
          Object.keys(merged).length > 0
            ? (merged as Prisma.InputJsonValue)
            : Prisma.DbNull,
      },
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.media.alt_update',
      resourceType: 'NewsMedia',
      resourceId: mediaId,
      metadata: { postId: media.postId },
    });

    // Published: defer revalidate until update-publish (see upload).

    const url = await this.signedUrls.getSignedGetUrl(updated.objectKey);
    const signed = new Map<string, string | null>([[updated.objectKey, url]]);
    return toMediaDto(updated, signed);
  }

  private async deleteMediaRecord(mediaId: string, objectKey: string): Promise<void> {
    await this.prisma.newsMedia.delete({ where: { id: mediaId } });
    this.signedUrls.invalidateKey(objectKey);
    if (this.s3.enabled) {
      try {
        await this.s3.deleteObject(objectKey);
      } catch (err) {
        this.logger.warn(`news.delete s3_failed key=${objectKey} err=${(err as Error).message}`);
      }
    }
  }
}

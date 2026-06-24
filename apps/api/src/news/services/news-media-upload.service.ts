import { BadRequestException, Injectable, Logger, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Prisma, type NewsMediaKind } from '../../prisma-client';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ImageContentValidator } from '../../storage/util/image-content-validator';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { NewsRevalidateService } from './news-revalidate.service';
import type { NewsLocale } from '../types/news.types';
import { toMediaDto } from './news-posts.mapper';

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const MAX_VIDEO_BYTES = 25 * 1024 * 1024;

const IMAGE_MIMES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/heic']);
const VIDEO_MIMES = new Set(['video/mp4', 'video/quicktime', 'video/webm']);

export type UploadNewsMediaInput = {
  postId: string;
  kind: 'cover' | 'inline_image' | 'inline_video';
  file: { buffer: Buffer; mimetype: string; size: number; originalname: string };
};

@Injectable()
export class NewsMediaUploadService {
  private readonly logger = new Logger(NewsMediaUploadService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
    private readonly imageValidator: ImageContentValidator,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
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
    if (post.status === 'PUBLISHED' && post.publishedAt && post.publishedAt <= new Date()) {
      // allow media on published posts for corrections via admin
    }

    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured',
      });
    }

    const prismaKind = this.toPrismaKind(input.kind);
    const { mime, ext } = this.validateFile(input.kind, input.file);

    const subfolder = input.kind === 'cover' ? 'cover' : 'inline';
    const key = `news/${input.postId}/${subfolder}/${randomUUID()}.${ext}`;

    try {
      await this.s3.putObject({
        Key: key,
        Body: input.file.buffer,
        ContentType: mime,
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
        mimeType: mime,
        fileName: input.file.originalname?.slice(0, 255) ?? null,
        sizeBytes: input.file.size,
        sortOrder: 0,
      },
    });

    if (input.kind === 'cover') {
      if (post.coverMediaId && post.coverMedia) {
        await this.deleteMediaRecord(post.coverMedia.id, post.coverMedia.objectKey);
      }
      await this.prisma.newsPost.update({
        where: { id: input.postId },
        data: { coverMediaId: media.id },
      });
    }

    await this.audit?.log({
      actorId: null,
      action: 'news.media.upload',
      resourceType: 'NewsMedia',
      resourceId: media.id,
      metadata: { postId: input.postId, kind: input.kind },
    });

    if (post.status === 'PUBLISHED' || post.status === 'SCHEDULED') {
      void this.revalidate.triggerLandingRevalidate();
    }

    const url = await this.signedUrls.getSignedGetUrl(key);
    return { ...media, url };
  }

  async deleteMedia(mediaId: string): Promise<void> {
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
    if (media.coverForPost) {
      await this.prisma.newsPost.update({
        where: { id: media.coverForPost.id },
        data: { coverMediaId: null },
      });
    }
    await this.deleteMediaRecord(media.id, media.objectKey);

    await this.audit?.log({
      actorId: null,
      action: 'news.media.delete',
      resourceType: 'NewsMedia',
      resourceId: mediaId,
      metadata: { postId: media.postId },
    });

    if (media.post.status === 'PUBLISHED' || media.post.status === 'SCHEDULED') {
      void this.revalidate.triggerLandingRevalidate();
    }
  }

  async updateAltText(mediaId: string, altText: Partial<Record<NewsLocale, string>>) {
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
      actorId: null,
      action: 'news.media.alt_update',
      resourceType: 'NewsMedia',
      resourceId: mediaId,
      metadata: { postId: media.postId },
    });

    if (media.post.status === 'PUBLISHED' || media.post.status === 'SCHEDULED') {
      void this.revalidate.triggerLandingRevalidate();
    }

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

  private toPrismaKind(kind: UploadNewsMediaInput['kind']): NewsMediaKind {
    switch (kind) {
      case 'cover':
        return 'COVER';
      case 'inline_image':
        return 'INLINE_IMAGE';
      case 'inline_video':
        return 'INLINE_VIDEO';
    }
  }

  private validateFile(
    kind: UploadNewsMediaInput['kind'],
    file: UploadNewsMediaInput['file'],
  ): { mime: string; ext: string } {
    const mime = file.mimetype?.toLowerCase() ?? '';
    if (kind === 'inline_video' || (kind === 'cover' && VIDEO_MIMES.has(mime))) {
      if (!VIDEO_MIMES.has(mime)) {
        throw new BadRequestException({
          code: 'NEWS_INVALID_VIDEO_TYPE',
          message: 'Video must be MP4, MOV, or WebM',
        });
      }
      if (file.size > MAX_VIDEO_BYTES) {
        throw new BadRequestException({
          code: 'NEWS_VIDEO_TOO_LARGE',
          message: 'Video exceeds maximum size',
        });
      }
      const ext = mime === 'video/quicktime' ? 'mov' : mime.split('/')[1] || 'mp4';
      return { mime, ext };
    }

    const { mime: validated } = this.imageValidator.assertReportImage(file, {
      maxBytes: MAX_IMAGE_BYTES,
    });
    if (!IMAGE_MIMES.has(validated)) {
      throw new BadRequestException({
        code: 'NEWS_INVALID_IMAGE_TYPE',
        message: 'Image must be JPEG, PNG, WebP, or HEIC',
      });
    }
    const ext =
      validated === 'image/jpeg' || validated === 'image/jpg'
        ? 'jpg'
        : validated.split('/')[1] || 'jpg';
    return { mime: validated, ext };
  }
}

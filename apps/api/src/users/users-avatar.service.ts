import { BadRequestException, Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import sharp from 'sharp';
import { randomUUID } from 'crypto';
import { S3StorageClient } from '../storage/s3-storage.client';

const ALLOWED_MIMES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);
const MAX_AVATAR_FILE_SIZE_BYTES = 8 * 1024 * 1024;
const AVATAR_SIGNED_URL_TTL_SECONDS = 15 * 60;

/**
 * Profile avatar upload + private key signing (bounded to users/auth concerns).
 */
@Injectable()
export class UsersAvatarService {
  private readonly logger = new Logger(UsersAvatarService.name);
  private readonly signedUrlCache = new Map<string, { url: string; expiresAt: number }>();

  constructor(private readonly s3: S3StorageClient) {}

  async uploadProfileAvatar(
    userId: string,
    file: { buffer: Buffer; mimetype: string; size: number; originalname: string },
  ): Promise<string> {
    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured. S3_BUCKET_NAME is required.',
      });
    }

    if (!file || !file.buffer || file.size <= 0) {
      throw new BadRequestException({
        code: 'AVATAR_FILE_REQUIRED',
        message: 'Avatar image file is required.',
      });
    }

    const normalizedMime = (file.mimetype || '').toLowerCase();
    if (!ALLOWED_MIMES.has(normalizedMime)) {
      throw new BadRequestException({
        code: 'INVALID_AVATAR_TYPE',
        message: 'Avatar must be a jpeg, png, or webp image.',
      });
    }
    if (file.size > MAX_AVATAR_FILE_SIZE_BYTES) {
      throw new BadRequestException({
        code: 'AVATAR_FILE_TOO_LARGE',
        message: 'Avatar exceeds 8MB limit.',
      });
    }

    const processed = await this.processAvatarImage(file.buffer);
    const objectKey = `profile-avatars/${userId}/${Date.now()}-${randomUUID()}.webp`;
    await this.s3.putObject({
      Key: objectKey,
      Body: processed,
      ContentType: 'image/webp',
      CacheControl: 'private, max-age=300',
    });
    return objectKey;
  }

  async signPrivateObjectKey(objectKey: string | null | undefined): Promise<string | null> {
    if (!objectKey || !this.s3.enabled) {
      return null;
    }
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      return null;
    }
    const now = Date.now();
    const cacheHit = this.signedUrlCache.get(objectKey);
    if (cacheHit && cacheHit.expiresAt > now) {
      return cacheHit.url;
    }
    try {
      const signed = await getSignedUrl(
        client,
        new GetObjectCommand({ Bucket: bucket, Key: objectKey }),
        { expiresIn: AVATAR_SIGNED_URL_TTL_SECONDS },
      );
      this.signedUrlCache.set(objectKey, {
        url: signed,
        expiresAt: now + 13 * 60 * 1000,
      });
      return signed;
    } catch {
      this.signedUrlCache.delete(objectKey);
      return null;
    }
  }

  async resolveUserAvatarUrl(stored: string | null | undefined): Promise<string | null> {
    const t = stored?.trim();
    if (!t) {
      return null;
    }
    if (t.startsWith('http://') || t.startsWith('https://')) {
      const base = this.s3.getVirtualHostedHttpsBase();
      if (!base || !t.startsWith(base)) {
        return t;
      }
      const key = decodeURIComponent(t.slice(base.length).split('?')[0]);
      return (await this.signPrivateObjectKey(key)) ?? t;
    }
    return this.signPrivateObjectKey(t);
  }

  invalidateSignedUrlCacheForKey(objectKey: string): void {
    this.signedUrlCache.delete(objectKey);
  }

  async deleteAvatarObjectByKey(objectKey: string | null | undefined): Promise<void> {
    if (!objectKey || !this.s3.enabled) {
      return;
    }
    this.invalidateSignedUrlCacheForKey(objectKey);
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      return;
    }
    try {
      await client.send(
        new DeleteObjectCommand({
          Bucket: bucket,
          Key: objectKey,
        }),
      );
    } catch (err) {
      this.logger.warn(`avatar.delete_failed key=${objectKey} err=${(err as Error).message}`);
    }
  }

  private async processAvatarImage(input: Buffer): Promise<Buffer> {
    try {
      const image = sharp(input, { failOn: 'error' });
      const meta = await image.metadata();
      const width = meta.width ?? 0;
      const height = meta.height ?? 0;
      if (width <= 0 || height <= 0) {
        throw new Error('invalid dimensions');
      }
      const square = Math.min(width, height);
      const left = Math.floor((width - square) / 2);
      const top = Math.floor((height - square) / 2);
      return await image
        .extract({ left, top, width: square, height: square })
        .resize(512, 512, { fit: 'cover' })
        .webp({ quality: 82, effort: 4 })
        .toBuffer();
    } catch {
      throw new BadRequestException({
        code: 'INVALID_AVATAR_IMAGE',
        message: 'Avatar image could not be processed.',
      });
    }
  }
}

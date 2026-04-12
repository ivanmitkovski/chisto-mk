import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import sharp from 'sharp';
import { randomUUID } from 'crypto';

const ALLOWED_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
]);
const IMAGE_EXTENSIONS = /\.(jpe?g|png|webp)$/i;
const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB
const MAX_AVATAR_FILE_SIZE_BYTES = 8 * 1024 * 1024; // 8MB
const AVATAR_SIGNED_URL_TTL_SECONDS = 15 * 60;

@Injectable()
export class ReportsUploadService {
  private readonly s3: S3Client | null = null;
  private readonly bucket: string | null = null;
  private readonly region: string;
  private readonly enabled: boolean;
  private readonly signedUrlCache = new Map<string, { url: string; expiresAt: number }>();

  constructor(private readonly configService: ConfigService) {
    this.region =
      this.configService.get<string>('AWS_REGION')?.trim() ||
      this.configService.get<string>('AWS_DEFAULT_REGION')?.trim() ||
      'eu-central-1';
    const bucket = this.configService.get<string>('S3_BUCKET_NAME')?.trim();
    this.bucket = bucket && bucket.length > 0 ? bucket : null;
    this.enabled = !!this.bucket;
    if (this.enabled) {
      this.s3 = new S3Client({ region: this.region });
    }
  }

  async uploadFiles(
    userId: string,
    files: Array<{ buffer: Buffer; mimetype: string; size: number; originalname: string }>,
  ): Promise<string[]> {
    if (!this.enabled || !this.s3 || !this.bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured. S3_BUCKET_NAME is required.',
      });
    }

    if (!files || files.length === 0) {
      return [];
    }

    if (files.length > 5) {
      throw new BadRequestException({
        code: 'TOO_MANY_FILES',
        message: 'Maximum 5 files allowed',
      });
    }

    const timestamp = Date.now();
    const urls: string[] = [];

    for (const file of files) {
      let mime = (file.mimetype || '').toLowerCase();
      if (!ALLOWED_MIMES.has(mime)) {
        if (mime === 'application/octet-stream' && file.originalname) {
          const ext = file.originalname.match(IMAGE_EXTENSIONS)?.[1];
          if (ext) {
            mime = ext.startsWith('jpeg') || ext.startsWith('jpg')
              ? 'image/jpeg'
              : ext === 'png'
                ? 'image/png'
                : 'image/webp';
          }
        }
      }
      if (!ALLOWED_MIMES.has(mime)) {
        throw new BadRequestException({
          code: 'INVALID_FILE_TYPE',
          message: `Invalid file type: ${file.mimetype}. Only jpeg, png, and webp are allowed.`,
        });
      }

      if (file.size > MAX_FILE_SIZE_BYTES) {
        throw new BadRequestException({
          code: 'FILE_TOO_LARGE',
          message: `File ${file.originalname} exceeds 10MB limit`,
        });
      }

      const ext = mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const safeName = (file.originalname || 'image')
        .replace(/[^a-zA-Z0-9.-]/g, '_')
        .slice(0, 100) || 'image';
      const key = `reports/${userId}/${timestamp}-${safeName}.${ext}`;

      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: file.buffer,
          ContentType: mime,
        }),
      );

      const url = `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;
      urls.push(url);
    }

    return urls;
  }

  /** Build canonical S3 HTTPS URLs for object keys (same shape as [uploadFiles]). */
  getPublicUrlsForKeys(keys: string[]): string[] {
    if (!this.bucket) {
      return keys;
    }
    const base = `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
    return keys.map((key) => `${base}${key}`);
  }

  /**
   * Converts S3 object URLs to presigned URLs (1h expiry) so clients can load
   * private objects. Non-S3 URLs are returned unchanged.
   */
  async signUrls(urls: string[]): Promise<string[]> {
    if (!this.enabled || !this.s3 || !this.bucket || !urls?.length) {
      return urls ?? [];
    }
    const base = `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
    const now = Date.now();
    const result: string[] = [];
    for (const url of urls) {
      if (typeof url !== 'string' || !url.startsWith(base)) {
        result.push(url);
        continue;
      }
      const key = decodeURIComponent(url.slice(base.length).split('?')[0]);
      const cacheHit = this.signedUrlCache.get(key);
      if (cacheHit && cacheHit.expiresAt > now) {
        result.push(cacheHit.url);
        continue;
      }
      try {
        const signed = await getSignedUrl(
          this.s3,
          new GetObjectCommand({ Bucket: this.bucket, Key: key }),
          { expiresIn: 3600 },
        );
        this.signedUrlCache.set(key, {
          url: signed,
          // Keep a safety buffer so we do not serve nearly-expired links.
          expiresAt: now + 50 * 60 * 1000,
        });
        result.push(signed);
      } catch {
        result.push(url);
      }
    }
    return result;
  }

  async uploadProfileAvatar(
    userId: string,
    file: { buffer: Buffer; mimetype: string; size: number; originalname: string },
  ): Promise<string> {
    if (!this.enabled || !this.s3 || !this.bucket) {
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
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: objectKey,
        Body: processed,
        ContentType: 'image/webp',
        CacheControl: 'private, max-age=300',
      }),
    );
    return objectKey;
  }

  async signPrivateObjectKey(objectKey: string | null | undefined): Promise<string | null> {
    if (!objectKey || !this.enabled || !this.s3 || !this.bucket) {
      return null;
    }
    const now = Date.now();
    const cacheHit = this.signedUrlCache.get(objectKey);
    if (cacheHit && cacheHit.expiresAt > now) {
      return cacheHit.url;
    }
    try {
      const signed = await getSignedUrl(
        this.s3,
        new GetObjectCommand({ Bucket: this.bucket, Key: objectKey }),
        { expiresIn: AVATAR_SIGNED_URL_TTL_SECONDS },
      );
      this.signedUrlCache.set(objectKey, {
        url: signed,
        expiresAt: now + 13 * 60 * 1000,
      });
      return signed;
    } catch {
      // Avoid failing profile reads when avatar object was removed or unavailable.
      this.signedUrlCache.delete(objectKey);
      return null;
    }
  }

  async deleteObjectByKey(objectKey: string | null | undefined): Promise<void> {
    if (!objectKey || !this.enabled || !this.s3 || !this.bucket) {
      return;
    }
    this.signedUrlCache.delete(objectKey);
    await this.s3.send(
      new DeleteObjectCommand({
        Bucket: this.bucket,
        Key: objectKey,
      }),
    );
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

  /**
   * After-cleanup photos for citizen events. Returns S3 object keys (not public URLs).
   */
  async uploadCleanupEventAfterImages(
    userId: string,
    eventId: string,
    files: Array<{ buffer: Buffer; mimetype: string; size: number; originalname: string }>,
  ): Promise<string[]> {
    if (!this.enabled || !this.s3 || !this.bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured. S3_BUCKET_NAME is required.',
      });
    }

    if (!files || files.length === 0) {
      return [];
    }

    if (files.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_FILES',
        message: 'Maximum 10 after-cleanup photos allowed',
      });
    }

    const keys: string[] = [];
    const baseTs = Date.now();

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      let mime = (file.mimetype || '').toLowerCase();
      if (!ALLOWED_MIMES.has(mime)) {
        if (mime === 'application/octet-stream' && file.originalname) {
          const extMatch = file.originalname.match(IMAGE_EXTENSIONS)?.[1];
          if (extMatch) {
            mime =
              extMatch.startsWith('jpeg') || extMatch.startsWith('jpg')
                ? 'image/jpeg'
                : extMatch === 'png'
                  ? 'image/png'
                  : 'image/webp';
          }
        }
      }
      if (!ALLOWED_MIMES.has(mime)) {
        throw new BadRequestException({
          code: 'INVALID_FILE_TYPE',
          message: `Invalid file type: ${file.mimetype}. Only jpeg, png, and webp are allowed.`,
        });
      }

      if (file.size > MAX_FILE_SIZE_BYTES) {
        throw new BadRequestException({
          code: 'FILE_TOO_LARGE',
          message: `File ${file.originalname} exceeds 10MB limit`,
        });
      }

      const ext =
        mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const key = `cleanup-events/${userId}/${eventId}/${baseTs}-${i}-${randomUUID()}.${ext}`;

      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: file.buffer,
          ContentType: mime,
        }),
      );

      keys.push(key);
    }

    return keys;
  }
}

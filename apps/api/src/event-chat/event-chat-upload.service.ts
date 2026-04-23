import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import sharp from 'sharp';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';

/** MIME/size caps mirror mobile `ChatUploadLimits` (apps/mobile/.../chat_upload_limits.dart). */
const IMAGE_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
]);

const VIDEO_MIMES = new Set([
  'video/mp4',
  'video/quicktime',
  'video/webm',
]);

const AUDIO_MIMES = new Set([
  'audio/mpeg',
  'audio/mp3',
  'audio/aac',
  'audio/m4a',
  'audio/ogg',
  'audio/wav',
]);

const DOC_MIMES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/plain',
]);

const ALL_ALLOWED_MIMES = new Set([...IMAGE_MIMES, ...VIDEO_MIMES, ...AUDIO_MIMES, ...DOC_MIMES]);

const MAX_IMAGE_SIZE = 10 * 1024 * 1024;
const MAX_VIDEO_SIZE = 25 * 1024 * 1024;
const MAX_AUDIO_SIZE = 10 * 1024 * 1024;
const MAX_DOC_SIZE = 10 * 1024 * 1024;
const MAX_FILES_PER_MESSAGE = 5;

function maxSizeForMime(mime: string): number {
  if (VIDEO_MIMES.has(mime)) return MAX_VIDEO_SIZE;
  if (AUDIO_MIMES.has(mime)) return MAX_AUDIO_SIZE;
  if (DOC_MIMES.has(mime)) return MAX_DOC_SIZE;
  return MAX_IMAGE_SIZE;
}

export interface ProcessedAttachment {
  url: string;
  mimeType: string;
  fileName: string;
  sizeBytes: number;
  width: number | null;
  height: number | null;
  duration: number | null;
  thumbnailUrl: string | null;
}

@Injectable()
export class EventChatUploadService {
  private readonly logger = new Logger(EventChatUploadService.name);
  private readonly s3: S3Client | null = null;
  private readonly bucket: string | null = null;
  private readonly region: string;
  private readonly enabled: boolean;
  private readonly signedGetEnabled: boolean;
  private static readonly SIGNED_GET_TTL_SECONDS = 3600;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.region =
      this.config.get<string>('AWS_REGION')?.trim() ||
      this.config.get<string>('AWS_DEFAULT_REGION')?.trim() ||
      'eu-central-1';
    const bucket = this.config.get<string>('S3_BUCKET_NAME')?.trim();
    this.bucket = bucket && bucket.length > 0 ? bucket : null;
    this.enabled = !!this.bucket;
    if (this.enabled) {
      this.s3 = new S3Client({ region: this.region });
    }
    const signFlag = this.config.get<string>('CHAT_SIGNED_ATTACHMENT_URLS')?.trim().toLowerCase();
    this.signedGetEnabled = this.enabled && (signFlag === 'true' || signFlag === '1');
  }

  private publishedUrlPrefix(): string | null {
    if (!this.bucket) {
      return null;
    }
    return `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
  }

  /** Extract S3 object key from a URL produced by [processAndUpload], or null if unknown. */
  keyFromChatPublishedUrl(url: string): string | null {
    const prefix = this.publishedUrlPrefix();
    if (!prefix || !url.startsWith(prefix)) {
      return null;
    }
    const key = decodeURIComponent(url.slice(prefix.length));
    if (!key.startsWith('chat/')) {
      return null;
    }
    return key;
  }

  async signChatPublishedUrl(url: string | null): Promise<string | null> {
    if (url == null || url === '' || !this.signedGetEnabled || !this.s3 || !this.bucket) {
      return url;
    }
    const key = this.keyFromChatPublishedUrl(url);
    if (!key) {
      return url;
    }
    try {
      const cmd = new GetObjectCommand({ Bucket: this.bucket, Key: key });
      return await getSignedUrl(this.s3, cmd, {
        expiresIn: EventChatUploadService.SIGNED_GET_TTL_SECONDS,
      });
    } catch (error) {
      this.logger.warn(`Signed GET failed for ${key.slice(0, 48)}: ${String(error)}`);
      return url;
    }
  }

  async applySignedUrlsToMessageDto(dto: EventChatMessageResponseDto): Promise<EventChatMessageResponseDto> {
    if (!this.signedGetEnabled || dto.attachments.length === 0) {
      return dto;
    }
    const attachments = await Promise.all(
      dto.attachments.map(async (a) => ({
        ...a,
        url: (await this.signChatPublishedUrl(a.url)) ?? a.url,
        thumbnailUrl: await this.signChatPublishedUrl(a.thumbnailUrl),
      })),
    );
    return { ...dto, attachments };
  }

  async processAndUpload(
    eventId: string,
    files: Array<{ buffer: Buffer; mimetype: string; size: number; originalname: string }>,
  ): Promise<ProcessedAttachment[]> {
    if (!this.enabled || !this.s3 || !this.bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured.',
      });
    }
    if (files.length > MAX_FILES_PER_MESSAGE) {
      throw new BadRequestException({
        code: 'CHAT_UPLOAD_TOO_MANY',
        message: `Maximum ${MAX_FILES_PER_MESSAGE} files per message.`,
      });
    }

    const results: ProcessedAttachment[] = [];

    for (const file of files) {
      if (!ALL_ALLOWED_MIMES.has(file.mimetype)) {
        throw new BadRequestException({
          code: 'CHAT_UPLOAD_MIME',
          message: `Unsupported file type: ${file.mimetype}`,
        });
      }
      const limit = maxSizeForMime(file.mimetype);
      if (file.size > limit) {
        throw new BadRequestException({
          code: 'CHAT_UPLOAD_SIZE',
          message: `File exceeds ${Math.round(limit / 1024 / 1024)} MB limit: ${file.originalname}`,
        });
      }

      if (IMAGE_MIMES.has(file.mimetype)) {
        const key = `chat/${eventId}/${randomUUID()}.webp`;
        const image = sharp(file.buffer);
        const meta = await image.metadata();
        const width = meta.width ?? null;
        const height = meta.height ?? null;
        const webp = await image.webp({ quality: 80 }).toBuffer();

        await this.s3.send(
          new PutObjectCommand({
            Bucket: this.bucket,
            Key: key,
            Body: webp,
            ContentType: 'image/webp',
            CacheControl: 'public, max-age=31536000, immutable',
          }),
        );

        results.push({
          url: `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`,
          mimeType: 'image/webp',
          fileName: file.originalname,
          sizeBytes: webp.length,
          width,
          height,
          duration: null,
          thumbnailUrl: null,
        });
      } else {
        const ext = file.originalname.split('.').pop()?.toLowerCase() || 'bin';
        const key = `chat/${eventId}/${randomUUID()}.${ext}`;

        await this.s3.send(
          new PutObjectCommand({
            Bucket: this.bucket,
            Key: key,
            Body: file.buffer,
            ContentType: file.mimetype,
            CacheControl: 'public, max-age=31536000, immutable',
          }),
        );

        results.push({
          url: `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`,
          mimeType: file.mimetype,
          fileName: file.originalname,
          sizeBytes: file.size,
          width: null,
          height: null,
          duration: null,
          thumbnailUrl: null,
        });
      }
    }

    return results;
  }

  /** Best-effort removal of objects uploaded under `chat/{eventId}/…` (matches [processAndUpload] URLs). */
  async deleteUploadedObjectsByUrls(urls: string[]): Promise<void> {
    if (!this.enabled || !this.s3 || !this.bucket || urls.length === 0) {
      return;
    }
    const prefix = `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
    const unique = [...new Set(urls.map((u) => u.trim()).filter((u) => u.length > 0))];
    for (const url of unique) {
      if (!url.startsWith(prefix)) {
        this.logger.warn(`Skipping S3 delete: URL not under expected chat bucket prefix`);
        continue;
      }
      const key = decodeURIComponent(url.slice(prefix.length));
      if (!key.startsWith('chat/')) {
        this.logger.warn(`Skipping S3 delete: key does not start with chat/: ${key.slice(0, 64)}`);
        continue;
      }
      try {
        await this.s3.send(
          new DeleteObjectCommand({
            Bucket: this.bucket,
            Key: key,
          }),
        );
      } catch (error) {
        this.logger.warn(`S3 delete failed for ${key}: ${String(error)}`);
      }
    }
  }

  async createAttachmentRecords(
    messageId: string,
    attachments: ProcessedAttachment[],
  ): Promise<void> {
    if (!attachments.length) return;
    await this.prisma.eventChatAttachment.createMany({
      data: attachments.map((a) => ({
        messageId,
        url: a.url,
        mimeType: a.mimeType,
        fileName: a.fileName,
        sizeBytes: a.sizeBytes,
        width: a.width,
        height: a.height,
        duration: a.duration,
        thumbnailUrl: a.thumbnailUrl,
      })),
    });
  }
}

import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
  Optional,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import sharp from 'sharp';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import type { EventChatMessageResponseDto } from '../dto/event-chat-message-response.dto';
import {
  ALL_ALLOWED_MIMES,
  IMAGE_MIMES,
  MAX_FILES_PER_MESSAGE,
  maxSizeForMime,
} from '../constants/event-chat-upload.constants';
import type { ProcessedAttachment } from '../types/event-chat-upload.types';

export { EVENT_CHAT_MULTER_MAX_FILE_BYTES } from '../constants/event-chat-upload.constants';
export type { ProcessedAttachment } from '../types/event-chat-upload.types';

@Injectable()
export class EventChatUploadService implements OnModuleInit {
  private readonly logger = new Logger(EventChatUploadService.name);
  private signedGetEnabled = false;
  private cfg!: (key: string) => string | undefined;
  private static readonly SIGNED_GET_TTL_SECONDS = 15 * 60;

  constructor(
    @Optional() private readonly config: ConfigService | null,
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
  ) {}

  onModuleInit(): void {
    this.cfg = (key: string) =>
      this.config?.get<string>(key)?.trim() ?? process.env[key]?.trim();
    const signFlag = this.cfg('CHAT_SIGNED_ATTACHMENT_URLS')?.toLowerCase();
    this.signedGetEnabled =
      this.s3.enabled && (signFlag === 'true' || signFlag === '1');
  }

  private publishedUrlPrefix(): string | null {
    return this.s3.getVirtualHostedHttpsBase();
  }

  /** True if [url] is a published object URL for this deployment's chat prefix (trusted for persistence). */
  isTrustedChatPublishedUrl(url: string): boolean {
    return this.keyFromChatPublishedUrl(url) != null;
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
    if (url == null || url === '' || !this.signedGetEnabled) {
      return url;
    }
    const key = this.keyFromChatPublishedUrl(url);
    if (!key) {
      return url;
    }
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      return url;
    }
    try {
      const cmd = new GetObjectCommand({ Bucket: bucket, Key: key });
      return await getSignedUrl(client, cmd, {
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
    if (!this.s3.enabled || !this.s3.bucket) {
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
    const base = this.publishedUrlPrefix()!;

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

        await this.s3.putObject({
          Key: key,
          Body: webp,
          ContentType: 'image/webp',
          CacheControl: 'public, max-age=31536000, immutable',
        });

        results.push({
          url: `${base}${key}`,
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
        await this.s3.putObject({
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype,
          CacheControl: 'public, max-age=31536000, immutable',
        });
        results.push({
          url: `${base}${key}`,
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
    if (!this.s3.enabled || urls.length === 0) {
      return;
    }
    const unique = [...new Set(urls.map((u) => u.trim()).filter((u) => u.length > 0))];
    for (const url of unique) {
      const key = this.keyFromChatPublishedUrl(url);
      if (!key) {
        this.logger.warn('Skipping S3 delete: URL not under expected chat bucket prefix');
        continue;
      }
      try {
        await this.s3.deleteObject(key);
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

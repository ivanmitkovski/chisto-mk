import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  type DeleteObjectCommandInput,
  ListObjectsV2Command,
  PutObjectCommand,
  type PutObjectCommandInput,
  S3Client,
} from '@aws-sdk/client-s3';

export type S3PutObjectParams = {
  Key: string;
  Body: NonNullable<PutObjectCommandInput['Body']>;
  ContentType: string;
  CacheControl?: string;
};

export type S3DeleteObjectParams = Pick<DeleteObjectCommandInput, 'Key'>;

/**
 * Thin AWS S3 facade for bounded contexts that need object I/O.
 * Single responsibility: SDK wiring + send; no domain validation.
 */
@Injectable()
export class S3StorageClient {
  private readonly logger = new Logger(S3StorageClient.name);
  readonly region: string;
  readonly bucket: string | null;
  readonly enabled: boolean;
  private readonly client: S3Client | null = null;

  constructor(private readonly configService: ConfigService) {
    this.region =
      this.configService.get<string>('AWS_REGION')?.trim() ||
      this.configService.get<string>('AWS_DEFAULT_REGION')?.trim() ||
      'eu-central-1';
    const bucket = this.configService.get<string>('S3_BUCKET_NAME')?.trim();
    this.bucket = bucket && bucket.length > 0 ? bucket : null;
    this.enabled = !!this.bucket;
    if (this.enabled) {
      this.client = new S3Client({ region: this.region });
    }
  }

  getVirtualHostedHttpsBase(): string | null {
    if (!this.bucket) {
      return null;
    }
    return `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
  }

  async putObject(params: S3PutObjectParams): Promise<void> {
    if (!this.enabled || !this.client || !this.bucket) {
      throw new Error('S3StorageClient.putObject called while S3 is disabled');
    }
    const input: PutObjectCommandInput = {
      Bucket: this.bucket,
      Key: params.Key,
      Body: params.Body,
      ContentType: params.ContentType,
    };
    if (params.CacheControl !== undefined) {
      input.CacheControl = params.CacheControl;
    }
    await this.client.send(new PutObjectCommand(input));
  }

  /**
   * List object keys under a prefix (for maintenance jobs). Returns up to [maxKeys] entries per call.
   */
  async listObjectsByPrefix(input: {
    prefix: string;
    maxKeys: number;
    continuationToken?: string;
  }): Promise<{
    objects: Array<{ key: string; lastModified: Date | null }>;
    continuationToken?: string;
  }> {
    if (!this.enabled || !this.client || !this.bucket) {
      return { objects: [] };
    }
    const out = await this.client.send(
      new ListObjectsV2Command({
        Bucket: this.bucket,
        Prefix: input.prefix,
        MaxKeys: input.maxKeys,
        ContinuationToken: input.continuationToken,
      }),
    );
    const objects: Array<{ key: string; lastModified: Date | null }> = [];
    for (const obj of out.Contents ?? []) {
      if (obj.Key) {
        objects.push({ key: obj.Key, lastModified: obj.LastModified ?? null });
      }
    }
    const next: {
      objects: Array<{ key: string; lastModified: Date | null }>;
      continuationToken?: string;
    } = { objects };
    if (out.IsTruncated && out.NextContinuationToken) {
      next.continuationToken = out.NextContinuationToken;
    }
    return next;
  }

  async deleteObject(key: string): Promise<void> {
    if (!key || !this.enabled || !this.client || !this.bucket) {
      return;
    }
    try {
      await this.client.send(
        new DeleteObjectCommand({
          Bucket: this.bucket,
          Key: key,
        }),
      );
    } catch (err) {
      this.logger.warn(`s3.delete_object_failed key=${key} err=${(err as Error).message}`);
      throw err;
    }
  }

  getClientOrNull(): S3Client | null {
    return this.client;
  }
}

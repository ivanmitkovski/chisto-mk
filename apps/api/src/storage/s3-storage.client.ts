import {
  Injectable,
  Logger,
  OnModuleInit,
  Optional,
  ServiceUnavailableException,
} from '@nestjs/common';
import { CircuitBreaker, CircuitBreakerOpenError } from '../common/resilience/circuit-breaker';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  type DeleteObjectCommandInput,
  ListObjectsV2Command,
  type ListObjectsV2CommandOutput,
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
export class S3StorageClient implements OnModuleInit {
  private readonly logger = new Logger(S3StorageClient.name);
  private readonly circuitBreaker = new CircuitBreaker({
    name: 's3',
    failureThreshold: 8,
    resetTimeoutMs: 45_000,
  });
  region = 'eu-central-1';
  bucket: string | null = null;
  enabled = false;
  private client: S3Client | null = null;

  constructor(@Optional() private readonly configService: ConfigService | null) {}

  onModuleInit(): void {
    const cfg = (key: string): string | undefined =>
      this.configService?.get<string>(key)?.trim() ?? process.env[key]?.trim();

    this.region = cfg('AWS_REGION') || cfg('AWS_DEFAULT_REGION') || 'eu-central-1';
    const bucketRaw = cfg('S3_BUCKET_NAME');
    this.bucket = bucketRaw && bucketRaw.length > 0 ? bucketRaw : null;
    this.enabled = Boolean(this.bucket);
    if (this.enabled) {
      const endpoint =
        cfg('S3_ENDPOINT_URL')?.trim() || cfg('AWS_S3_ENDPOINT')?.trim() || cfg('AWS_ENDPOINT_URL')?.trim() || undefined;
      const forceRaw = cfg('S3_FORCE_PATH_STYLE')?.trim().toLowerCase();
      const forcePathStyle =
        forceRaw === 'true' || forceRaw === '1'
          ? true
          : forceRaw === 'false' || forceRaw === '0'
            ? false
            : Boolean(endpoint);
      this.client = new S3Client({
        region: this.region,
        ...(endpoint ? { endpoint, forcePathStyle } : {}),
      });
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
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is not configured for this environment.',
      });
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
    try {
      await this.circuitBreaker.execute(async () => {
        await this.client!.send(new PutObjectCommand(input));
      });
    } catch (err) {
      if (err instanceof CircuitBreakerOpenError) {
        throw new ServiceUnavailableException({
          code: 'S3_CIRCUIT_OPEN',
          message: 'Object storage is temporarily unavailable. Please retry later.',
        });
      }
      throw err;
    }
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
    let out: ListObjectsV2CommandOutput;
    try {
      out = await this.circuitBreaker.execute(async () =>
        this.client!.send(
          new ListObjectsV2Command({
            Bucket: this.bucket!,
            Prefix: input.prefix,
            MaxKeys: input.maxKeys,
            ContinuationToken: input.continuationToken,
          }),
        ),
      );
    } catch (err) {
      if (err instanceof CircuitBreakerOpenError) {
        return { objects: [] };
      }
      throw err;
    }
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
      await this.circuitBreaker.execute(async () =>
        this.client!.send(
          new DeleteObjectCommand({
            Bucket: this.bucket!,
            Key: key,
          }),
        ),
      );
    } catch (err) {
      if (err instanceof CircuitBreakerOpenError) {
        this.logger.warn(`s3.delete_object_circuit_open key=${key}`);
        return;
      }
      this.logger.warn(`s3.delete_object_failed key=${key} err=${(err as Error).message}`);
      throw err;
    }
  }

  getClientOrNull(): S3Client | null {
    return this.client;
  }
}

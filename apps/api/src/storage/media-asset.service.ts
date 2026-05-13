import { PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { S3StorageClient } from './s3-storage.client';

export type PresignedPutRequest = {
  /** Private object key (caller must enforce prefix policy / auth). */
  key: string;
  contentType: string;
  /** Suggested max upload size hint for clients only (not enforced by S3 URL). */
  maxBytesHint?: number;
  /** Presigned URL TTL (default 15 minutes). */
  expiresInSeconds?: number;
};

export type PresignedPutResult = {
  uploadUrl: string;
  key: string;
  expiresInSeconds: number;
  maxBytesHint?: number;
};

/**
 * Cross-cutting media upload surface (Phase 2.6): presigned PUT for direct client→S3 uploads.
 * Sharp-based processing in feature services remains until a Lambda consumer is deployed.
 */
@Injectable()
export class MediaAssetService {
  constructor(private readonly s3: S3StorageClient) {}

  /**
   * Issues a short-lived presigned PUT URL so browsers/mobile clients upload bytes directly to S3.
   * After upload, feature modules should persist the returned `key` and run any Sharp/Lambda pipeline as configured.
   */
  async createPresignedPutUrl(input: PresignedPutRequest): Promise<PresignedPutResult> {
    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is not configured for this environment.',
      });
    }
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is not configured for this environment.',
      });
    }
    const expiresInSeconds = input.expiresInSeconds ?? 15 * 60;
    const cmd = new PutObjectCommand({
      Bucket: bucket,
      Key: input.key,
      ContentType: input.contentType,
    });
    const uploadUrl = await getSignedUrl(client, cmd, { expiresIn: expiresInSeconds });
    return {
      uploadUrl,
      key: input.key,
      expiresInSeconds,
      ...(input.maxBytesHint !== undefined ? { maxBytesHint: input.maxBytesHint } : {}),
    };
  }
}

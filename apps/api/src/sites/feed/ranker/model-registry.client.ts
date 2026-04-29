import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Readable } from 'node:stream';

export type FeedModelManifest = {
  version: string;
  modelKey: string;
  sha256: string;
};

@Injectable()
export class ModelRegistryClient {
  private readonly s3: S3Client;

  constructor(private readonly config: ConfigService) {
    const region =
      this.config.get<string>('AWS_REGION')?.trim() ||
      this.config.get<string>('AWS_DEFAULT_REGION')?.trim() ||
      'eu-central-1';
    this.s3 = new S3Client({ region });
  }

  async latestManifest(): Promise<FeedModelManifest | null> {
    const version = this.config.get<string>('FEED_V2_MODEL_VERSION')?.trim();
    if (!version) return null;
    return {
      version,
      modelKey: `chisto-feed-models/${this.config.get<string>('ENV') ?? 'dev'}/${version}/model.onnx`,
      sha256: this.config.get<string>('FEED_V2_MODEL_SHA256') ?? '',
    };
  }

  async downloadModel(manifest: FeedModelManifest): Promise<Buffer> {
    const bucket = this.config.get<string>('FEED_V2_MODEL_BUCKET')?.trim();
    if (!bucket) {
      throw new Error('FEED_V2_MODEL_BUCKET is required when FEED_V2_ONNX_ENABLED=true');
    }
    const out = await this.s3.send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: manifest.modelKey,
      }),
    );
    if (!out.Body) {
      throw new Error('Feed model object has empty body');
    }
    return streamToBuffer(out.Body as Readable);
  }
}

async function streamToBuffer(stream: Readable): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

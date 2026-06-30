import { Injectable, OnModuleInit, Optional, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Readable } from 'node:stream';

export type FeedModelManifest = {
  version: string;
  modelKey: string;
  sha256: string;
};

@Injectable()
export class ModelRegistryClient implements OnModuleInit {
  private s3!: S3Client;
  private read!: (key: string) => string | undefined;

  constructor(@Optional() private readonly config: ConfigService | null) {}

  onModuleInit(): void {
    this.read = (key: string) =>
      this.config?.get<string>(key)?.trim() ?? process.env[key]?.trim();
    const region =
      this.read('AWS_REGION') || this.read('AWS_DEFAULT_REGION') || 'eu-central-1';
    this.s3 = new S3Client({ region });
  }

  async latestManifest(): Promise<FeedModelManifest | null> {
    const version = this.read('FEED_V2_MODEL_VERSION');
    if (!version) return null;
    return {
      version,
      modelKey: `chisto-feed-models/${this.read('ENV') ?? 'dev'}/${version}/model.onnx`,
      sha256: this.read('FEED_V2_MODEL_SHA256') ?? '',
    };
  }

  async downloadModel(manifest: FeedModelManifest): Promise<Buffer> {
    const bucket = this.read('FEED_V2_MODEL_BUCKET');
    if (!bucket) {
      throw new ServiceUnavailableException({
        code: 'FEED_RANKER_UNAVAILABLE',
        message: 'FEED_V2_MODEL_BUCKET is required when FEED_V2_ONNX_ENABLED=true.',
      });
    }
    const out = await this.s3.send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: manifest.modelKey,
      }),
    );
    if (!out.Body) {
      throw new ServiceUnavailableException({
        code: 'FEED_RANKER_UNAVAILABLE',
        message: 'Feed model object has empty body.',
      });
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

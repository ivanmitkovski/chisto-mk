import { BadGatewayException, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type CdnProvider = 'cloudfront' | 'cloudflare' | 'none';

const RETRY_DELAYS_MS = [500, 1500, 4500];

@Injectable()
export class MapCdnPurgeService {
  private readonly logger = new Logger(MapCdnPurgeService.name);
  private readonly provider: CdnProvider;

  constructor(private readonly prisma: PrismaService) {
    const raw = process.env.CDN_PROVIDER ?? 'none';
    this.provider = (['cloudfront', 'cloudflare', 'none'] as const).includes(
      raw as CdnProvider,
    )
      ? (raw as CdnProvider)
      : 'none';
  }

  enqueueSurrogateKeys(keys: string[]): void {
    if (keys.length === 0) return;

    this.logger.log({ msg: 'map_cdn_purge_enqueued', keys, provider: this.provider });

    if (this.provider === 'none') return;

    void this.purgeWithRetry(keys);
  }

  private async purgeWithRetry(keys: string[]): Promise<void> {
    for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
      try {
        if (this.provider === 'cloudfront') {
          await this.purgeCloudFront(keys);
        } else {
          await this.purgeCloudflare(keys);
        }

        this.logger.log({
          msg: 'map_cdn_purge_success',
          provider: this.provider,
          keys,
          attempt: attempt + 1,
        });
        await this.recordPurgeLog(keys, 'SUCCESS');
        return;
      } catch (err) {
        const isLastAttempt = attempt >= RETRY_DELAYS_MS.length;
        const errorMessage = err instanceof Error ? err.message : String(err);
        this.logger.warn({
          msg: 'map_cdn_purge_failed',
          provider: this.provider,
          keys,
          attempt: attempt + 1,
          error: errorMessage,
          willRetry: !isLastAttempt,
        });

        if (isLastAttempt) {
          await this.recordPurgeLog(keys, 'FAILED', errorMessage);
          return;
        }
        await this.sleep(RETRY_DELAYS_MS[attempt]);
      }
    }
  }

  private async purgeCloudFront(keys: string[]): Promise<void> {
    const distributionId = process.env.CDN_DISTRIBUTION_ID;
    if (!distributionId) {
      this.logger.warn({ msg: 'map_cdn_purge_skip', reason: 'CDN_DISTRIBUTION_ID not set' });
      return;
    }

    interface CloudFrontClientLike {
      send(command: unknown): Promise<unknown>;
    }
    interface CloudFrontCtor {
      new (): CloudFrontClientLike;
    }
    interface InvalidationCtor {
      new (input: unknown): unknown;
    }
    let CloudFrontClient: CloudFrontCtor;
    let CreateInvalidationCommand: InvalidationCtor;
    try {
      // String indirection prevents TypeScript from resolving the optional dependency at compile time
      const moduleName = '@aws-sdk/client-cloudfront';
      const sdk = await (Function('m', 'return import(m)')(moduleName) as Promise<{
        CloudFrontClient: CloudFrontCtor;
        CreateInvalidationCommand: InvalidationCtor;
      }>);
      CloudFrontClient = sdk.CloudFrontClient;
      CreateInvalidationCommand = sdk.CreateInvalidationCommand;
    } catch {
      this.logger.warn({
        msg: 'map_cdn_purge_skip',
        reason: '@aws-sdk/client-cloudfront not installed',
      });
      return;
    }

    const paths = keys.map((k) => `/${k.replace(/^\//, '')}`);

    const client = new CloudFrontClient();
    const command = new CreateInvalidationCommand({
      DistributionId: distributionId,
      InvalidationBatch: {
        CallerReference: `chisto-map-${Date.now()}`,
        Paths: { Quantity: paths.length, Items: paths },
      },
    });
    await client.send(command);
  }

  private async purgeCloudflare(keys: string[]): Promise<void> {
    const zoneId = process.env.CDN_ZONE_ID;
    const apiToken = process.env.CDN_API_TOKEN;

    if (!zoneId || !apiToken) {
      this.logger.warn({
        msg: 'map_cdn_purge_skip',
        reason: 'CDN_ZONE_ID or CDN_API_TOKEN not set',
      });
      return;
    }

    const url = `https://api.cloudflare.com/client/v4/zones/${zoneId}/purge_cache`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ tags: keys }),
    });

    if (!response.ok) {
      const body = await response.text().catch(() => '<unreadable>');
      throw new BadGatewayException({
        code: 'MAP_CDN_PURGE_FAILED',
        message: 'Cloudflare cache purge failed',
        details: { status: response.status, bodyPreview: body.slice(0, 500) },
      });
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private async recordPurgeLog(
    keys: string[],
    status: 'SUCCESS' | 'FAILED',
    errorMessage?: string,
  ): Promise<void> {
    try {
      await this.prisma.$executeRaw`
        INSERT INTO "MapCdnPurgeLog" ("id", "provider", "status", "keys", "errorMessage")
        VALUES (md5(random()::text || clock_timestamp()::text), ${this.provider}, ${status}, ${JSON.stringify(keys)}::jsonb, ${errorMessage ?? null})
      `;
    } catch (error) {
      this.logger.warn({
        msg: 'map_cdn_purge_log_write_failed',
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
}

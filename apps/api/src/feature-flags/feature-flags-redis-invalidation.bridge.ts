import { Injectable, Logger, OnModuleDestroy, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OnEvent } from '@nestjs/event-emitter';
import Redis from 'ioredis';
import { FeatureFlagsService } from './feature-flags.service';

const FEATURE_FLAGS_INVALIDATION_CHANNEL = 'chisto:feature_flags:invalidate';

@Injectable()
export class FeatureFlagsRedisInvalidationBridge implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(FeatureFlagsRedisInvalidationBridge.name);
  private publisher: Redis | null = null;
  private subscriber: Redis | null = null;

  constructor(
    @Optional() private readonly config: ConfigService | null,
    private readonly flags: FeatureFlagsService,
  ) {}

  @OnEvent('feature_flags.patch', { async: true })
  async publishLocalPatch(): Promise<void> {
    if (!this.publisher) {
      return;
    }
    try {
      await this.publisher.publish(FEATURE_FLAGS_INVALIDATION_CHANNEL, '1');
    } catch (err) {
      this.logger.warn(
        `Redis feature-flag invalidation publish failed: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }

  onModuleInit(): void {
    const url = this.config?.get<string>('REDIS_URL')?.trim();
    if (!url || process.env.NODE_ENV === 'test') {
      return;
    }
    try {
      this.publisher = new Redis(url, { maxRetriesPerRequest: 2, enableReadyCheck: true });
      this.subscriber = this.publisher.duplicate();
      this.subscriber.on('message', (channel) => {
        if (channel !== FEATURE_FLAGS_INVALIDATION_CHANNEL) {
          return;
        }
        this.flags.applyRemoteFeatureFlagInvalidation();
      });
      void this.subscriber.subscribe(FEATURE_FLAGS_INVALIDATION_CHANNEL).catch((err) => {
        this.logger.error(
          `Redis feature-flag invalidation subscribe failed: ${err instanceof Error ? err.message : String(err)}`,
        );
      });
    } catch (err) {
      this.logger.error(
        `Redis feature-flag invalidation bridge failed to start: ${err instanceof Error ? err.message : String(err)}`,
      );
      void this.publisher?.quit().catch(() => {});
      void this.subscriber?.quit().catch(() => {});
      this.publisher = null;
      this.subscriber = null;
    }
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.all([
      this.subscriber?.quit().catch(() => {}),
      this.publisher?.quit().catch(() => {}),
    ]);
  }
}

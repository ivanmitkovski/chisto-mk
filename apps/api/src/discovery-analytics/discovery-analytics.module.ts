import { DynamicModule, Module } from '@nestjs/common';
import { DiscoveryAnalyticsController } from './discovery-analytics.controller';

@Module({})
export class DiscoveryAnalyticsModule {
  /**
   * Registers ingest routes only when `DISCOVERY_ANALYTICS_INGEST_SECRET` is set,
   * or in `NODE_ENV=test` (tests can set the secret per case).
   */
  static register(): DynamicModule {
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    const secret = process.env.DISCOVERY_ANALYTICS_INGEST_SECRET?.trim();
    if (nodeEnv !== 'test' && !secret) {
      return { module: DiscoveryAnalyticsModule, controllers: [] };
    }
    return { module: DiscoveryAnalyticsModule, controllers: [DiscoveryAnalyticsController] };
  }
}

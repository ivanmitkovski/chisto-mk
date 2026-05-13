import { DynamicModule, Module } from '@nestjs/common';
import { MetricsController } from './metrics.controller';

@Module({})
export class ObservabilityModule {
  /**
   * Registers `/metrics` only when `METRICS_BEARER_TOKEN` is set, or in `NODE_ENV=test`
   * (so CI can opt-in without exposing unauthenticated metrics in shared dev/staging).
   */
  static register(): DynamicModule {
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    const token = process.env.METRICS_BEARER_TOKEN?.trim();
    if (nodeEnv !== 'test' && !token) {
      return { module: ObservabilityModule, controllers: [] };
    }
    return { module: ObservabilityModule, controllers: [MetricsController] };
  }
}

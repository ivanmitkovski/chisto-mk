import { Module } from '@nestjs/common';
import { DiscoveryAnalyticsController } from './discovery-analytics.controller';

@Module({
  controllers: [DiscoveryAnalyticsController],
})
export class DiscoveryAnalyticsModule {}

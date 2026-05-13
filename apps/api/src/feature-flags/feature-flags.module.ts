import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsController } from './feature-flags.controller';
import { FeatureFlagsRedisInvalidationBridge } from './feature-flags-redis-invalidation.bridge';
import { FeatureFlagsService } from './feature-flags.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, ConfigModule],
  controllers: [FeatureFlagsController],
  providers: [FeatureFlagsService, FeatureFlagsRedisInvalidationBridge],
  exports: [FeatureFlagsService],
})
export class FeatureFlagsModule {}

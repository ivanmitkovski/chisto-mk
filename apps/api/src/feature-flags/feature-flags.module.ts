import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsController } from './controllers/feature-flags.controller';
import { FeatureFlagsRedisInvalidationBridge } from './util/feature-flags-redis-invalidation.bridge';
import { FeatureFlagsService } from './services/feature-flags.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, ConfigModule],
  controllers: [FeatureFlagsController],
  providers: [FeatureFlagsService, FeatureFlagsRedisInvalidationBridge],
  exports: [FeatureFlagsService],
})
export class FeatureFlagsModule {}

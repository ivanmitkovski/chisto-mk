import { Module } from '@nestjs/common';
import { PublicConfigController } from './public-config.controller';
import { SystemConfigModule } from '../system-config/system-config.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';

@Module({
  imports: [SystemConfigModule, FeatureFlagsModule],
  controllers: [PublicConfigController],
})
export class PublicConfigModule {}

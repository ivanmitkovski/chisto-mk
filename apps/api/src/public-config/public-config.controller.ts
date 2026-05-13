import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SystemConfigService } from '../system-config/system-config.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('config')
@ApiStandardHttpErrorResponses()
@Controller('config')
export class PublicConfigController {
  constructor(
    private readonly systemConfig: SystemConfigService,
    private readonly featureFlagsService: FeatureFlagsService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Public environment and API URL hints' })
  @ApiOkResponse({ description: 'Public configuration' })
  async get() {
    return this.systemConfig.getPublic();
  }

  @Get('feature-flags')
  @ApiOperation({ summary: 'Public feature flags map' })
  @ApiOkResponse({ description: 'Feature flags' })
  async getFeatureFlags() {
    const flags = await this.featureFlagsService.getPublicMap();
    return { flags };
  }
}

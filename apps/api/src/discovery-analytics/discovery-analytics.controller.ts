import { Body, Controller, Logger, Post, UseGuards } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { DiscoveryAnalyticsIngestDto } from './discovery-analytics-ingest.dto';

@ApiTags('discovery-analytics')
@Controller('discovery-analytics')
@UseGuards(ThrottlerGuard)
export class DiscoveryAnalyticsController {
  private readonly logger = new Logger(DiscoveryAnalyticsController.name);

  constructor(private readonly configService: ConfigService) {}

  @Post('events')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({
    summary:
      'Discovery funnel beacon (first-party; gated by DISCOVERY_ANALYTICS_ENABLED on the server)',
  })
  @ApiOkResponse({
    description: '{ ok: true, accepted: boolean }',
    schema: { example: { ok: true, accepted: true } },
  })
  ingest(@Body() body: DiscoveryAnalyticsIngestDto): { ok: true; accepted: boolean } {
    const enabled = this.configService.get<string>('DISCOVERY_ANALYTICS_ENABLED', 'false') === 'true';
    if (!enabled) {
      return { ok: true, accepted: false };
    }
    const appMajor = body.appVersion.split('.')[0] ?? '';
    this.logger.log(
      JSON.stringify({
        context: 'discovery_analytics',
        step: body.step,
        platform: body.platform,
        appMajor,
      }),
    );
    return { ok: true, accepted: true };
  }
}

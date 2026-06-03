import { Controller, Get, Header, Headers, UnauthorizedException } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ObservabilityStore } from '../observability.store';
import { renderLegacyMetricsExposition } from '../util/metrics-legacy.exposition';
import { renderPrometheusMetrics } from '../util/prom-registry';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { timingSafeEqualString } from '../../common/security/timing-safe-equal.util';

@ApiTags('metrics')
@ApiStandardHttpErrorResponses()
@Controller('metrics')
export class MetricsController {
  @Get()
  @Header('Content-Type', 'text/plain; version=0.0.4')
  @ApiOperation({ summary: 'Prometheus text exposition (protected outside development when METRICS_BEARER_TOKEN is set)' })
  async metrics(@Headers('authorization') authorization?: string): Promise<string> {
    const token = process.env.METRICS_BEARER_TOKEN?.trim();
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    const mustBeProtected = nodeEnv !== 'development' && nodeEnv !== 'test';
    if (mustBeProtected && !token) {
      throw new UnauthorizedException({
        code: 'METRICS_UNAUTHORIZED',
        message: 'Metrics bearer token is required in non-local environments',
      });
    }
    const expected = `Bearer ${token}`;
    if ((mustBeProtected || !!token) && (!authorization || !timingSafeEqualString(authorization, expected))) {
      throw new UnauthorizedException({
        code: 'METRICS_UNAUTHORIZED',
        message: 'Metrics access denied',
      });
    }
    ObservabilityStore.syncLegacyPromGauges();
    const promNative = await renderPrometheusMetrics();
    const legacyLines = renderLegacyMetricsExposition(ObservabilityStore.snapshot());
    return `${promNative}\n${legacyLines}`;
  }
}

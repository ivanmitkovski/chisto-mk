import { UnauthorizedException } from '@nestjs/common';
import { MetricsController } from '../../src/observability/metrics.controller';

describe('MetricsController', () => {
  const originalToken = process.env.METRICS_BEARER_TOKEN;

  afterEach(() => {
    if (originalToken == null) {
      delete process.env.METRICS_BEARER_TOKEN;
    } else {
      process.env.METRICS_BEARER_TOKEN = originalToken;
    }
  });

  it('allows metrics when no bearer token is configured', async () => {
    delete process.env.METRICS_BEARER_TOKEN;

    const body = await new MetricsController().metrics();
    expect(body).toContain('chisto_http_requests_total');
  });

  it('rejects metrics when bearer token is configured and missing', async () => {
    process.env.METRICS_BEARER_TOKEN = 'secret';

    await expect(new MetricsController().metrics()).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('allows metrics with the configured bearer token', async () => {
    process.env.METRICS_BEARER_TOKEN = 'secret';

    const body = await new MetricsController().metrics('Bearer secret');
    expect(body).toContain('feed_v2_ranker_mode_info');
  });
});

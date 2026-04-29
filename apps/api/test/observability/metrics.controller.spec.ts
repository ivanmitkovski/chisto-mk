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

  it('allows metrics when no bearer token is configured', () => {
    delete process.env.METRICS_BEARER_TOKEN;

    expect(new MetricsController().metrics()).toContain('api_requests_total');
  });

  it('rejects metrics when bearer token is configured and missing', () => {
    process.env.METRICS_BEARER_TOKEN = 'secret';

    expect(() => new MetricsController().metrics()).toThrow(UnauthorizedException);
  });

  it('allows metrics with the configured bearer token', () => {
    process.env.METRICS_BEARER_TOKEN = 'secret';

    expect(new MetricsController().metrics('Bearer secret')).toContain(
      'feed_v2_ranker_mode_info',
    );
  });
});

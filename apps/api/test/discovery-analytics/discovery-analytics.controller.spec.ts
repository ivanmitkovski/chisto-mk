/// <reference types="jest" />
import { DiscoveryAnalyticsController } from '../../src/discovery-analytics/discovery-analytics.controller';
import { DiscoveryAnalyticsIngestDto } from '../../src/discovery-analytics/discovery-analytics-ingest.dto';

describe('DiscoveryAnalyticsController', () => {
  const dto: DiscoveryAnalyticsIngestDto = {
    eventId: '550e8400-e29b-41d4-a716-446655440000',
    step: 'detail_view',
    platform: 'ios',
    appVersion: '1.0.0',
  };

  it('returns accepted false when server flag is off', () => {
    const config = { get: jest.fn(() => 'false') };
    const ctrl = new DiscoveryAnalyticsController(config as never);
    expect(ctrl.ingest(dto)).toEqual({ ok: true, accepted: false });
  });

  it('returns accepted true when server flag is on', () => {
    const config = { get: jest.fn(() => 'true') };
    const ctrl = new DiscoveryAnalyticsController(config as never);
    expect(ctrl.ingest(dto)).toEqual({ ok: true, accepted: true });
  });
});

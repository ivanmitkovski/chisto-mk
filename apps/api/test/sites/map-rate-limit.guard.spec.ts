/// <reference types="jest" />

jest.mock('../../src/config/map.config', () => ({
  loadMapConfig: () => require('../helpers/mock-map-config').mockMapConfigNoRedis(),
}));

import type { ExecutionContext } from '@nestjs/common';
import { HttpException } from '@nestjs/common';
import { MapRateLimitGuard } from '../../src/sites/http/map-rate-limit.guard';

function contextForRequest(req: Record<string, unknown>): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => req,
    }),
  } as unknown as ExecutionContext;
}

describe('MapRateLimitGuard', () => {
  let guard: MapRateLimitGuard;

  afterEach(async () => {
    await guard?.onModuleDestroy();
  });

  it('allows request when redis is absent in non-production', async () => {
    guard = new MapRateLimitGuard();
    (guard as any).redis = null;
    await expect(
      guard.canActivate(
        contextForRequest({
          headers: {},
          ip: '127.0.0.1',
          route: { path: '/sites/map' },
          path: '/sites/map',
        }),
      ),
    ).resolves.toBe(true);
  });

  it('applies SSE route limit when accept header is event-stream', async () => {
    guard = new MapRateLimitGuard();
    const redisMock = {
      connect: jest.fn(async () => undefined),
      eval: jest.fn(async () => 121),
      quit: jest.fn(async () => undefined),
    };
    (guard as any).redis = redisMock;
    await expect(
      guard.canActivate(
        contextForRequest({
          headers: { accept: 'text/event-stream' },
          ip: '127.0.0.1',
          route: { path: '/sites/events' },
          path: '/sites/events',
        }),
      ),
    ).rejects.toBeInstanceOf(HttpException);
  });
});

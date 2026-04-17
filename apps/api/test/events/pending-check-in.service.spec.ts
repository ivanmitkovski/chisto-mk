/// <reference types="jest" />

import { ConfigService } from '@nestjs/config';
import { PendingCheckInService } from '../../src/events/pending-check-in.service';

describe('PendingCheckInService', () => {
  it('allows in-memory fallback when NODE_ENV is test and CHECK_IN_REQUIRE_REDIS is unset', () => {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'NODE_ENV') return 'test';
        if (key === 'CHECK_IN_REQUIRE_REDIS') return undefined;
        if (key === 'CHECK_IN_CONFIRM_TTL_SEC') return undefined;
        if (key === 'REDIS_URL') return undefined;
        return undefined;
      }),
    } as unknown as ConfigService;

    const svc = new PendingCheckInService(config);
    expect(() => svc.onModuleInit()).not.toThrow();
  });

  it('throws on module init when Redis is required but REDIS_URL is missing', () => {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'NODE_ENV') return 'production';
        if (key === 'REDIS_URL') return undefined;
        if (key === 'CHECK_IN_CONFIRM_TTL_SEC') return undefined;
        return undefined;
      }),
    } as unknown as ConfigService;

    const svc = new PendingCheckInService(config);
    expect(() => svc.onModuleInit()).toThrow(/Redis is required/);
  });

  it('throws on module init when CHECK_IN_REQUIRE_REDIS is true without REDIS_URL', () => {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'NODE_ENV') return 'development';
        if (key === 'CHECK_IN_REQUIRE_REDIS') return 'true';
        if (key === 'REDIS_URL') return undefined;
        if (key === 'CHECK_IN_CONFIRM_TTL_SEC') return undefined;
        return undefined;
      }),
    } as unknown as ConfigService;

    const svc = new PendingCheckInService(config);
    expect(() => svc.onModuleInit()).toThrow(/Redis is required/);
  });
});

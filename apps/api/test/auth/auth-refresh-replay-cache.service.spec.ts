/// <reference types="jest" />

import { Logger } from '@nestjs/common';
import { AuthRefreshReplayCacheService } from '../../src/auth/services/auth-refresh-replay-cache.service';

describe('AuthRefreshReplayCacheService', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
    delete process.env.REDIS_URL;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('logs error in production when REDIS_URL is missing', () => {
    process.env.NODE_ENV = 'production';
    const errorSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    const service = new AuthRefreshReplayCacheService();
    service.onModuleInit();
    expect(errorSpy).toHaveBeenCalledWith(
      expect.stringContaining('REDIS_URL is not configured'),
    );
    errorSpy.mockRestore();
    service.onModuleDestroy();
  });

  it('logs error in development when REDIS_URL is missing', () => {
    process.env.NODE_ENV = 'development';
    const errorSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    const service = new AuthRefreshReplayCacheService();
    service.onModuleInit();
    expect(errorSpy).toHaveBeenCalledWith(
      expect.stringContaining('REDIS_URL is not configured'),
    );
    errorSpy.mockRestore();
    service.onModuleDestroy();
  });
});

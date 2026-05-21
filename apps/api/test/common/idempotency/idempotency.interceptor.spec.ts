/// <reference types="jest" />
import { ConflictException } from '@nestjs/common';
import { of } from 'rxjs';
import { IdempotencyInterceptor } from '../../../src/common/idempotency/idempotency.interceptor';
import { IdempotencyResponseStore } from '../../../src/common/idempotency/idempotency-response.store';

describe('IdempotencyInterceptor', () => {
  it('caches only 2xx responses', async () => {
    const store = {
      get: jest.fn().mockResolvedValue(null),
      tryAcquireInFlightLock: jest.fn().mockResolvedValue(true),
      releaseInFlightLock: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(undefined),
    } as unknown as IdempotencyResponseStore;
    const reflector = { get: jest.fn().mockReturnValue('test_scope') } as never;
    const interceptor = new IdempotencyInterceptor(reflector, store);

    const req = {
      headers: { 'x-idempotency-key': '12345678' },
      method: 'POST',
      path: '/v1/foo',
      user: { userId: 'u1' },
    };
    const res = { statusCode: 400 };
    const ctx = {
      getHandler: () => ({}),
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => res,
      }),
    } as never;

    await interceptor.intercept(ctx, { handle: () => of({ ok: false }) });
    expect(store.set).not.toHaveBeenCalled();
  });

  it('returns conflict when lock is held and no cached response', async () => {
    jest.useFakeTimers();
    const store = {
      get: jest.fn().mockResolvedValue(null),
      tryAcquireInFlightLock: jest.fn().mockResolvedValue(false),
      releaseInFlightLock: jest.fn(),
      set: jest.fn(),
    } as unknown as IdempotencyResponseStore;
    const reflector = { get: jest.fn().mockReturnValue('test_scope') } as never;
    const interceptor = new IdempotencyInterceptor(reflector, store);
    const req = {
      headers: { 'x-idempotency-key': '12345678' },
      method: 'POST',
      path: '/v1/foo',
      user: { userId: 'u1' },
    };
    const ctx = {
      getHandler: () => ({}),
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => ({ statusCode: 200 }),
      }),
    } as never;

    const pending = interceptor.intercept(ctx, { handle: () => of({ ok: true }) });
    const assertion = expect(pending).rejects.toBeInstanceOf(ConflictException);
    await jest.advanceTimersByTimeAsync(31_000);
    await assertion;
    jest.useRealTimers();
  });
});

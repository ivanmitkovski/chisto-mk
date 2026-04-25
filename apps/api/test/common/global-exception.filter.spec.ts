/// <reference types="jest" />

import { HttpStatus, Logger } from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import { GlobalExceptionFilter } from '../../src/common/filters/global-exception.filter';

describe('GlobalExceptionFilter', () => {
  it('maps ThrottlerException to 429 with TOO_MANY_REQUESTS body', () => {
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'GET', url: '/test', requestId: 'rid-1' }),
      }),
    };

    filter.catch(new ThrottlerException(), host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.TOO_MANY_REQUESTS);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'TOO_MANY_REQUESTS',
        message: 'Too many requests. Please wait and try again.',
        retryable: true,
        retryAfterSeconds: 60,
        timestamp: expect.any(String),
      }),
    );
  });

  it('logs unhandled errors with Nest Logger (structured JSON string)', () => {
    const logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'GET', url: '/boom', requestId: 'rid-2' }),
      }),
    };

    filter.catch(new Error('unexpected'), host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
        timestamp: expect.any(String),
      }),
    );
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('"context":"GlobalExceptionFilter"'));
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('rid-2'));
    logSpy.mockRestore();
  });
});

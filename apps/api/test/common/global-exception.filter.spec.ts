/// <reference types="jest" />

import { HttpStatus } from '@nestjs/common';
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
});

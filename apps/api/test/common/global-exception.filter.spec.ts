/// <reference types="jest" />

import { HttpStatus, Logger } from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import { MulterError } from 'multer';
import { GlobalExceptionFilter } from '../../src/common/filters/global-exception.filter';
import { Prisma } from '../../src/prisma-client';

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

  it('maps MulterError LIMIT_FILE_SIZE to 413 with PAYLOAD_TOO_LARGE body', () => {
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'POST', url: '/reports', requestId: 'rid-multer' }),
      }),
    };

    filter.catch(new MulterError('LIMIT_FILE_SIZE'), host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.PAYLOAD_TOO_LARGE);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'PAYLOAD_TOO_LARGE',
        retryable: false,
        details: expect.objectContaining({
          maxBytes: expect.any(Number),
          maxFiles: expect.any(Number),
        }),
        timestamp: expect.any(String),
      }),
    );
  });

  it('maps Prisma P2002 on ReportSubmitIdempotency to 409 DUPLICATE_SUBMIT_INFLIGHT', () => {
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'POST', url: '/reports', requestId: 'rid-p2002' }),
      }),
    };

    const err = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: 'test',
      meta: { modelName: 'ReportSubmitIdempotency' },
    });

    filter.catch(err, host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'DUPLICATE_SUBMIT_INFLIGHT',
        retryable: true,
        retryAfterSeconds: 5,
        timestamp: expect.any(String),
      }),
    );
  });

  it('maps Prisma P2002 on userId+key target to 409 DUPLICATE_SUBMIT_INFLIGHT', () => {
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'POST', url: '/reports', requestId: 'rid-p2002b' }),
      }),
    };

    const err = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: 'test',
      meta: { target: ['userId', 'key'] },
    });

    filter.catch(err, host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'DUPLICATE_SUBMIT_INFLIGHT',
        timestamp: expect.any(String),
      }),
    );
  });

  it('maps Prisma P2025 to 404 DATABASE_RECORD_NOT_FOUND', () => {
    const filter = new GlobalExceptionFilter();
    const json = jest.fn();
    const status = jest.fn().mockReturnValue({ json });
    const host = {
      switchToHttp: () => ({
        getResponse: () => ({ status }),
        getRequest: () => ({ method: 'DELETE', url: '/x', requestId: 'rid-p2025' }),
      }),
    };

    const err = new Prisma.PrismaClientKnownRequestError('Record not found', {
      code: 'P2025',
      clientVersion: 'test',
      meta: {},
    });

    filter.catch(err, host as never);

    expect(status).toHaveBeenCalledWith(HttpStatus.NOT_FOUND);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'DATABASE_RECORD_NOT_FOUND',
        retryable: false,
        timestamp: expect.any(String),
      }),
    );
  });
});

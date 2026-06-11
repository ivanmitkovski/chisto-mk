/// <reference types="jest" />

import type { Request, Response } from 'express';
import {
  pathFromRequest,
  shouldCompressResponse,
} from '../../src/bootstrap/should-compress-response';

function mockRequest(overrides: Partial<Request> = {}): Request {
  return {
    headers: {},
    url: '/v1/sites/map',
    originalUrl: '/v1/sites/map',
    method: 'GET',
    ...overrides,
  } as Request;
}

function mockResponse(contentType?: string): Response {
  return {
    getHeader: (name: string) =>
      name.toLowerCase() === 'content-type' ? contentType : undefined,
  } as Response;
}

describe('pathFromRequest', () => {
  it('strips query string from originalUrl', () => {
    expect(
      pathFromRequest(
        mockRequest({ originalUrl: '/v1/sites/events?foo=1', url: '/sites/events?foo=1' }),
      ),
    ).toBe('/v1/sites/events');
  });
});

describe('shouldCompressResponse', () => {
  it('returns false for Socket.IO paths', () => {
    expect(
      shouldCompressResponse(
        mockRequest({ originalUrl: '/socket.io/?EIO=4' }),
        mockResponse(),
      ),
    ).toBe(false);
  });

  it('returns false for map SSE route', () => {
    expect(
      shouldCompressResponse(
        mockRequest({ originalUrl: '/v1/sites/events' }),
        mockResponse(),
      ),
    ).toBe(false);
  });

  it('returns false when Accept is text/event-stream', () => {
    expect(
      shouldCompressResponse(
        mockRequest({
          originalUrl: '/v1/other',
          headers: { accept: 'text/event-stream' },
        }),
        mockResponse(),
      ),
    ).toBe(false);
  });

  it('returns false when Content-Type is text/event-stream', () => {
    expect(
      shouldCompressResponse(
        mockRequest({ originalUrl: '/v1/other' }),
        mockResponse('text/event-stream; charset=utf-8'),
      ),
    ).toBe(false);
  });

  it('returns true for a normal JSON GET when compressible', () => {
    expect(
      shouldCompressResponse(
        mockRequest({
          originalUrl: '/v1/sites/map',
          headers: { accept: 'application/json' },
        }),
        mockResponse('application/json'),
      ),
    ).toBe(true);
  });
});

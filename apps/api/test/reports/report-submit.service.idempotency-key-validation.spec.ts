/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import { ReportSubmitIdempotencyService } from '../../src/reports/report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from '../../src/reports/report-submit-media-append.service';
import { ReportSubmitService } from '../../src/reports/report-submit.service';
import { Role } from '../../src/prisma-client';

describe('ReportSubmitService idempotency key validation', () => {
  const user = {
    userId: 'user-1',
    email: 'u@x.com',
    roles: [Role.USER],
  };

  const dto = {
    latitude: 41.9973,
    longitude: 21.428,
    title: 'Test report title here',
    description: 'Desc',
    mediaUrls: [] as string[],
    category: 'OTHER' as const,
    severity: 3,
    address: 'Addr',
    cleanupEffort: null as null,
  };

  const prisma = {
    reportSubmitIdempotency: { findUnique: jest.fn() },
    $transaction: jest.fn(),
  };

  const postCreateEvents = { emit: jest.fn() };
  const reportsOwnerEventsService = { emit: jest.fn(), emitToReportInterestedParties: jest.fn() };
  const reportCapacity = { spendWithinTransaction: jest.fn() };
  const reportsUpload = { assertReportMediaUrlsFromOurBucket: jest.fn() };
  const nearbySiteResolver = { resolveEarliestReportAnchor: jest.fn() };

  const idempotency = new ReportSubmitIdempotencyService(prisma as never);
  const mediaAppend = new ReportSubmitMediaAppendService(
    prisma as never,
    reportsUpload as never,
    reportsOwnerEventsService as never,
  );
  const svc = new ReportSubmitService(
    prisma as never,
    postCreateEvents as never,
    reportsOwnerEventsService as never,
    reportCapacity as never,
    reportsUpload as never,
    nearbySiteResolver as never,
    idempotency,
    mediaAppend,
  );

  it('throws INVALID_IDEMPOTENCY_KEY when key is shorter than 16', async () => {
    try {
      await svc.createWithLocation(user as never, dto as never, '123456789012345', 'en');
      fail('expected BadRequestException');
    } catch (e) {
      expect(e).toBeInstanceOf(BadRequestException);
      const body = (e as BadRequestException).getResponse() as { code?: string };
      expect(body.code).toBe('INVALID_IDEMPOTENCY_KEY');
    }
  });

  it('throws INVALID_IDEMPOTENCY_KEY when key longer than 128', async () => {
    const long = 'a'.repeat(129);
    await expect(svc.createWithLocation(user as never, dto as never, long, 'en')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('throws INVALID_IDEMPOTENCY_KEY when key contains invalid characters', async () => {
    const bad = 'a'.repeat(15) + ' '; // 16 chars but space invalid
    await expect(svc.createWithLocation(user as never, dto as never, bad, 'en')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

});

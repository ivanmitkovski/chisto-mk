/// <reference types="jest" />
import { ReportCitizenQueryService } from '../../src/reports/report-citizen-query.service';
import { ReportSubmitIdempotencyService } from '../../src/reports/report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from '../../src/reports/report-submit-media-append.service';
import { ReportSubmitService } from '../../src/reports/report-submit.service';
import { ReportCapacityService } from '../../src/reports/report-capacity.service';
import { ReportsService } from '../../src/reports/reports.service';
import { Role } from '../../src/prisma-client';

function makeService(overrides?: {
  reportCreditsAvailable?: number;
  reportEmergencyWindowDays?: number;
  reportEmergencyUsedAt?: Date | null;
}) {
  const hasEmergencyOverride =
    overrides && Object.prototype.hasOwnProperty.call(overrides, 'reportEmergencyUsedAt');
  const prisma: any = {
    site: {
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn(),
    },
    report: {
      create: jest.fn(),
    },
    reportCoReporter: {
      upsert: jest.fn(),
    },
    adminNotification: {
      create: jest.fn(),
    },
    pointTransaction: {
      findFirst: jest.fn().mockResolvedValue(null),
    },
    user: {
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      findUnique: jest.fn().mockResolvedValue({
        id: 'user-1',
        reportCreditsAvailable: overrides?.reportCreditsAvailable ?? 0,
        reportEmergencyWindowDays: overrides?.reportEmergencyWindowDays ?? 7,
        reportEmergencyUsedAt: hasEmergencyOverride ? overrides?.reportEmergencyUsedAt ?? null : new Date(),
      }),
      update: jest.fn(),
    },
    $transaction: jest.fn(),
  };
  prisma.$transaction.mockImplementation(async (cb: (tx: unknown) => Promise<unknown>) => cb(prisma));

  const reportsUploadService = {
    signUrls: jest.fn(),
    deleteReportMediaUrls: jest.fn().mockResolvedValue(0),
    tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    assertReportMediaUrlsFromOurBucket: jest.fn(),
  };
  const reportsOwnerEventsService = { emit: jest.fn(), emitToReportInterestedParties: jest.fn() };
  const postCreateEvents = { emit: jest.fn() };

  const reportCapacity = new ReportCapacityService(prisma as never);
  const nearbySiteResolver = { resolveEarliestReportAnchor: jest.fn().mockResolvedValue(null) };
  const idempotency = new ReportSubmitIdempotencyService(prisma as never);
  const mediaAppend = new ReportSubmitMediaAppendService(
    prisma as never,
    reportsUploadService as never,
    reportsOwnerEventsService as never,
  );
  const reportSubmit = new ReportSubmitService(
    prisma as never,
    postCreateEvents as never,
    reportsOwnerEventsService as never,
    reportCapacity,
    reportsUploadService as never,
    nearbySiteResolver as never,
    idempotency,
    mediaAppend,
  );
  const reportCitizenQuery = new ReportCitizenQueryService(prisma as never, reportsUploadService as never);

  const service = new ReportsService(
    prisma as never,
    reportSubmit,
    reportCitizenQuery,
    reportCapacity,
    {} as never,
    {} as never,
  );

  return { service, prisma };
}

describe('ReportsService capacity guards', () => {
  const user = {
    userId: 'user-1',
    email: 'u@x.com',
    phoneNumber: '+38970111111',
    role: Role.USER,
  };

  const dto = {
    latitude: 41.9981,
    longitude: 21.4254,
    title: 'Test title',
    description: 'Test',
    category: null,
    severity: null,
    mediaUrls: [],
  };

  it('blocks submission with REPORTING_COOLDOWN when no credits and emergency already used', async () => {
    const lastEmergency = new Date(Date.now() - 60 * 60 * 1000); // 1 hour ago, still in 7-day window
    const { service } = makeService({
      reportCreditsAvailable: 0,
      reportEmergencyWindowDays: 7,
      reportEmergencyUsedAt: lastEmergency,
    });

    await expect(service.createWithLocation(user as never, dto as never)).rejects.toMatchObject({
      response: expect.objectContaining({
        code: 'REPORTING_COOLDOWN',
      }),
    });
  });

  it('returns current capacity for user', async () => {
    const { service } = makeService({
      reportCreditsAvailable: 3,
      reportEmergencyWindowDays: 7,
      reportEmergencyUsedAt: null,
    });

    const result = await service.getCapacityForCurrentUser(user as never);
    expect(result.creditsAvailable).toBe(3);
    expect(result.emergencyAvailable).toBe(true);
    expect(result.nextEmergencyReportAvailableAt).toBeNull();
    expect(result.unlockHint).toContain('unlock');
  });

  it('reports emergency unavailable with retryAfterSeconds when in window', async () => {
    const lastEmergency = new Date(Date.now() - 2 * 60 * 1000);
    const { service } = makeService({
      reportCreditsAvailable: 0,
      reportEmergencyWindowDays: 7,
      reportEmergencyUsedAt: lastEmergency,
    });

    const result = await service.getCapacityForCurrentUser(user as never);
    expect(result.emergencyAvailable).toBe(false);
    expect((result.retryAfterSeconds ?? 0) > 0).toBe(true);
    expect(result.nextEmergencyReportAvailableAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });
});

describe('ReportsService createWithLocation payload', () => {
  const user = {
    userId: 'user-1',
    email: 'u@x.com',
    phoneNumber: '+38970111111',
    role: Role.USER,
  };

  it('creates new site with address on Site (no narrative on Site) and cleanupEffort on Report', async () => {
    const { service, prisma } = makeService({
      reportCreditsAvailable: 5,
      reportEmergencyUsedAt: null,
    });
    prisma.site.create.mockResolvedValue({ id: 'site-new' });
    prisma.report.create.mockResolvedValue({
      id: 'r-new',
      createdAt: new Date('2025-06-01T12:00:00.000Z'),
      reportNumber: 'CH-000099',
    });
    prisma.adminNotification.create.mockResolvedValue({
      id: 'notif-1',
      title: 'New pollution site reported',
    });

    await service.createWithLocation(user as never, {
      latitude: 41.9981,
      longitude: 21.4254,
      title: 'Headline at site',
      description: 'Narrative only on report',
      address: ' Skopje ',
      cleanupEffort: 'THREE_TO_FIVE',
      category: 'OTHER',
      severity: 3,
      mediaUrls: [],
    } as never);

    expect(prisma.site.create).toHaveBeenCalledWith({
      data: {
        latitude: 41.9981,
        longitude: 21.4254,
        address: 'Skopje',
        description: null,
      },
    });
    expect(prisma.report.create).toHaveBeenCalledWith({
      data: {
        siteId: 'site-new',
        title: 'Headline at site',
        description: 'Narrative only on report',
        mediaUrls: [],
        reporterId: 'user-1',
        potentialDuplicateOfId: null,
        category: 'OTHER',
        severity: 3,
        cleanupEffort: 'THREE_TO_FIVE',
      },
    });
  });
});

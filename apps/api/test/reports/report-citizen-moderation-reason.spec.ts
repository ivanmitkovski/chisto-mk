/// <reference types="jest" />
import { ReportCitizenQueryService } from '../../src/reports/services/report-citizen-query.service';
import { citizenModerationReasonForResponse } from '../../src/reports/util/citizen-moderation-reason';
import { ReportStatus, Role } from '../../src/prisma-client';

describe('citizenModerationReasonForResponse', () => {
  it('returns trimmed reason only for DELETED', () => {
    expect(
      citizenModerationReasonForResponse(
        ReportStatus.DELETED,
        '  Insufficient evidence. Notes: More detail  ',
      ),
    ).toBe('Insufficient evidence. Notes: More detail');
    expect(
      citizenModerationReasonForResponse(
        ReportStatus.APPROVED,
        'should not leak',
      ),
    ).toBeNull();
    expect(citizenModerationReasonForResponse(ReportStatus.DELETED, '   ')).toBeNull();
  });
});

describe('ReportCitizenQueryService moderationReason', () => {
  const primaryUser = {
    userId: 'user-primary',
    email: 'p@x.com',
    phoneNumber: '+38970111111',
    role: Role.USER,
  };

  const coUser = {
    userId: 'user-co',
    email: 'c@x.com',
    phoneNumber: '+38970222222',
    role: Role.USER,
  };

  function makeCitizenQuery(prisma: Record<string, unknown>) {
    const upload = { signUrls: jest.fn().mockResolvedValue([]) };
    return new ReportCitizenQueryService(prisma as never, upload as never);
  }

  const rejectedReason =
    'Insufficient evidence. Notes: The evidence is not enough';

  it('findOneForCitizen returns moderationReason when DELETED', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date('2026-01-01T12:00:00.000Z'),
      status: 'DELETED',
      moderationReason: rejectedReason,
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
      reportNumber: 'CH-1',
      severity: null,
      cleanupEffort: null,
      site: {
        id: 'site-1',
        latitude: 41.99,
        longitude: 21.42,
        description: null,
        address: 'Addr',
      },
      reporter: { firstName: 'P', lastName: 'R' },
      coReporters: [],
    };

    const prisma: any = {
      report: { findUnique: jest.fn().mockResolvedValue(reportRow) },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const dto = await makeCitizenQuery(prisma).findOneForCitizen(
      'rep-1',
      primaryUser as never,
    );
    expect(dto.moderationReason).toBe(rejectedReason);
  });

  it('findOneForCitizen omits moderationReason when APPROVED', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date('2026-01-01T12:00:00.000Z'),
      status: 'APPROVED',
      moderationReason: rejectedReason,
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
      reportNumber: 'CH-1',
      severity: null,
      cleanupEffort: null,
      site: {
        id: 'site-1',
        latitude: 41.99,
        longitude: 21.42,
        description: null,
        address: null,
      },
      reporter: { firstName: 'P', lastName: 'R' },
      coReporters: [],
    };

    const prisma: any = {
      report: { findUnique: jest.fn().mockResolvedValue(reportRow) },
      pointTransaction: {
        findMany: jest.fn().mockResolvedValue([{ delta: 10 }]),
      },
    };

    const dto = await makeCitizenQuery(prisma).findOneForCitizen(
      'rep-1',
      primaryUser as never,
    );
    expect(dto.moderationReason).toBeNull();
  });

  it('co-reporter sees moderationReason on rejected report', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date('2026-01-01T12:00:00.000Z'),
      status: 'DELETED',
      moderationReason: rejectedReason,
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
      reportNumber: 'CH-1',
      severity: null,
      cleanupEffort: null,
      site: {
        id: 'site-1',
        latitude: 41.99,
        longitude: 21.42,
        description: null,
        address: 'Addr',
      },
      reporter: { firstName: 'P', lastName: 'R' },
      coReporters: [
        { userId: 'user-co', user: { firstName: 'C', lastName: 'O' } },
      ],
    };

    const prisma: any = {
      report: { findUnique: jest.fn().mockResolvedValue(reportRow) },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const dto = await makeCitizenQuery(prisma).findOneForCitizen(
      'rep-1',
      coUser as never,
    );
    expect(dto.moderationReason).toBe(rejectedReason);
    expect(dto.viewerRole).toBe('co_reporter');
  });

  it('findForCurrentUser includes moderationReason for DELETED rows', async () => {
    const prisma: any = {
      $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
      report: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'rep-del',
            reporterId: 'user-primary',
            reportNumber: 'CH-2',
            title: 'Rejected',
            description: null,
            category: null,
            createdAt: new Date('2026-01-02'),
            status: 'DELETED',
            moderationReason: rejectedReason,
            potentialDuplicateOfId: null,
            potentialDuplicates: [],
            coReporters: [],
            site: { latitude: 1, longitude: 2, description: null, address: 'A' },
            mediaUrls: [],
            severity: null,
            cleanupEffort: null,
          },
        ]),
        count: jest.fn().mockResolvedValue(1),
      },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const list = await makeCitizenQuery(prisma).findForCurrentUser(
      primaryUser as never,
      { page: 1, limit: 20 } as never,
    );
    expect(list.data[0].moderationReason).toBe(rejectedReason);
  });
});

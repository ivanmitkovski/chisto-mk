/// <reference types="jest" />
import { NotFoundException } from '@nestjs/common';
import { ReportCitizenQueryService } from '../../src/reports/report-citizen-query.service';
import { Role } from '../../src/prisma-client';

describe('ReportCitizenQueryService co-reporter access', () => {
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

  it('findOneForCitizen returns detail for co-reporter with viewerRole co_reporter and zero points', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date('2026-01-01T12:00:00.000Z'),
      status: 'APPROVED',
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
      site: {
        id: 'site-1',
        latitude: 41.99,
        longitude: 21.42,
        description: null,
        address: 'Addr',
      },
      reporter: { firstName: 'P', lastName: 'R' },
      coReporters: [
        {
          userId: 'user-co',
          user: { firstName: 'C', lastName: 'O' },
        },
      ],
    };

    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue(reportRow),
      },
      pointTransaction: {
        findMany: jest.fn().mockResolvedValue([{ delta: 50 }]),
      },
    };

    const service = makeCitizenQuery(prisma);
    const dto = await service.findOneForCitizen('rep-1', coUser as never);

    expect(dto.viewerRole).toBe('co_reporter');
    expect(dto.pointsAwarded).toBe(0);
    expect(dto.reporterName).toBe('P R');
    expect(prisma.pointTransaction.findMany).not.toHaveBeenCalled();
  });

  it('findOneForCitizen returns points for primary reporter', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date('2026-01-01T12:00:00.000Z'),
      status: 'APPROVED',
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
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
      report: {
        findUnique: jest.fn().mockResolvedValue(reportRow),
      },
      pointTransaction: {
        findMany: jest.fn().mockResolvedValue([{ delta: 50 }]),
      },
    };

    const service = makeCitizenQuery(prisma);
    const dto = await service.findOneForCitizen('rep-1', primaryUser as never);

    expect(dto.viewerRole).toBe('primary');
    expect(dto.pointsAwarded).toBe(50);
    expect(prisma.pointTransaction.findMany).toHaveBeenCalled();
  });

  it('findOneForCitizen rejects user who is neither reporter nor co-reporter', async () => {
    const reportRow = {
      id: 'rep-1',
      reporterId: 'user-primary',
      createdAt: new Date(),
      status: 'NEW',
      title: 'T',
      description: null,
      category: null,
      mediaUrls: [],
      site: {
        id: 'site-1',
        latitude: 1,
        longitude: 2,
        description: null,
        address: null,
      },
      reporter: { firstName: 'P', lastName: 'R' },
      coReporters: [],
    };

    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue(reportRow),
      },
    };

    const service = makeCitizenQuery(prisma);
    const stranger = { ...coUser, userId: 'stranger' };
    await expect(service.findOneForCitizen('rep-1', stranger as never)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('findForCurrentUser includes co-reported primaries with viewerRole and zero points', async () => {
    const prisma: any = {
      $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
      report: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'rep-primary',
            reporterId: 'user-primary',
            reportNumber: 'CH-1',
            title: 'Primary',
            description: null,
            category: null,
            createdAt: new Date('2026-01-01'),
            status: 'APPROVED',
            potentialDuplicateOfId: null,
            potentialDuplicates: [],
            coReporters: [{ userId: 'user-co' }],
            site: { latitude: 1, longitude: 2, description: null, address: 'A' },
            mediaUrls: [],
            severity: null,
            cleanupEffort: null,
          },
        ]),
        count: jest.fn().mockResolvedValue(1),
      },
      pointTransaction: {
        findMany: jest.fn().mockResolvedValue([{ referenceId: 'rep-primary', delta: 100 }]),
      },
    };

    const service = makeCitizenQuery(prisma);
    const list = await service.findForCurrentUser(coUser as never, { page: 1, limit: 20 } as never);

    expect(prisma.report.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          OR: [{ reporterId: 'user-co' }, { coReporters: { some: { userId: 'user-co' } } }],
        },
      }),
    );
    expect(list.data).toHaveLength(1);
    expect(list.data[0].viewerRole).toBe('co_reporter');
    expect(list.data[0].pointsAwarded).toBe(0);
  });
});

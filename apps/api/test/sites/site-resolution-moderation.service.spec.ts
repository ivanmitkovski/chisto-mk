/// <reference types="jest" />
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { SiteResolutionStatus, SiteStatus } from '../../src/prisma-client';
import { SiteResolutionModerationService } from '../../src/sites/resolutions/services/site-resolution-moderation.service';
import { transitionSiteToCleanedOnResolution } from '../../src/sites/resolutions/util/transition-site-to-cleaned-on-resolution.helper';

function createModerationService(deps: {
  prisma: unknown;
  resolutionPoints?: {
    creditApprovalIfEligible: jest.Mock;
    debitRevokedApprovalIfNeeded: jest.Mock;
  };
}) {
  const resolutionPoints = deps.resolutionPoints ?? {
    creditApprovalIfEligible: jest.fn().mockResolvedValue(null),
    debitRevokedApprovalIfNeeded: jest.fn().mockResolvedValue(0),
  };
  return new SiteResolutionModerationService(
    deps.prisma as never,
    { log: jest.fn() } as never,
    { emitSiteUpdated: jest.fn() } as never,
    {
      write: jest.fn(),
      recordStatusChanged: jest.fn(),
      emitHistoryAppended: jest.fn(),
    } as never,
    { invalidateFeedCache: jest.fn() } as never,
    { invalidateMapCache: jest.fn() } as never,
    { emitSiteStatusUpdate: jest.fn() } as never,
    resolutionPoints as never,
    {
      notifyResolutionApproved: jest.fn(),
      notifyResolutionRejected: jest.fn(),
      notifySiteResolved: jest.fn(),
      notifySubmitter: jest.fn(),
    } as never,
    { emit: jest.fn() } as never,
  );
}

describe('transitionSiteToCleanedOnResolution', () => {
  it('transitions VERIFIED site to CLEANED', async () => {
    const tx: any = {
      site: {
        findUnique: jest.fn().mockResolvedValue({
          id: 's1',
          status: SiteStatus.VERIFIED,
          latitude: 41.99,
          longitude: 21.43,
          updatedAt: new Date('2026-01-01T00:00:00.000Z'),
        }),
        update: jest.fn().mockResolvedValue({
          id: 's1',
          status: SiteStatus.CLEANED,
          latitude: 41.99,
          longitude: 21.43,
          updatedAt: new Date('2026-01-02T00:00:00.000Z'),
        }),
      },
    };

    const result = await transitionSiteToCleanedOnResolution(tx, 's1');
    expect(result?.status).toBe(SiteStatus.CLEANED);
    expect(result?.fromStatus).toBe(SiteStatus.VERIFIED);
  });

  it('no-ops when site is already CLEANED', async () => {
    const tx: any = {
      site: {
        findUnique: jest.fn().mockResolvedValue({
          id: 's1',
          status: SiteStatus.CLEANED,
          latitude: 41.99,
          longitude: 21.43,
          updatedAt: new Date(),
        }),
        update: jest.fn(),
      },
    };

    const result = await transitionSiteToCleanedOnResolution(tx, 's1');
    expect(result).toBeNull();
    expect(tx.site.update).not.toHaveBeenCalled();
  });
});

describe('SiteResolutionModerationService', () => {
  it('requires rejection reason', async () => {
    const prisma: any = {
      siteResolution: {
        findUnique: jest.fn(),
      },
    };
    const service = createModerationService({ prisma });

    await expect(
      service.updateStatus(
        'res-1',
        { status: SiteResolutionStatus.REJECTED },
        { userId: 'mod-1', role: 'ADMIN' } as never,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('returns not found for missing resolution', async () => {
    const prisma: any = {
      siteResolution: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
    };
    const service = createModerationService({ prisma });

    await expect(
      service.updateStatus(
        'missing',
        { status: SiteResolutionStatus.APPROVED },
        { userId: 'mod-1', role: 'ADMIN' } as never,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects invalid status transitions', async () => {
    const prisma: any = {
      siteResolution: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'res-1',
          siteId: 's1',
          status: SiteResolutionStatus.REJECTED,
          submittedById: 'u1',
          isReporterSubmission: false,
          mediaUrls: ['https://cdn.example/a.jpg'],
        }),
      },
    };
    const service = createModerationService({ prisma });

    await expect(
      service.updateStatus(
        'res-1',
        { status: SiteResolutionStatus.APPROVED },
        { userId: 'mod-1', role: 'ADMIN' } as never,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});

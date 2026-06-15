/// <reference types="jest" />

import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AdminModerationCategory, SiteStatus } from '../../src/prisma-client';
import { SiteResolutionSubmitService } from '../../src/sites/resolutions/services/site-resolution-submit.service';

const SITE_ID = 'c1234567890abcdefghijklmn';
const USER_ID = 'c2345678901bcdefghijklmno';
const RESOLUTION_ID = 'c3456789012cdefghijklmnop';

function createSubmitService(deps: {
  prisma: unknown;
  upload?: { assertMediaUrlsFromOurBucket: jest.Mock; signUrls: jest.Mock };
  query?: { listForSite: jest.Mock };
  siteHistoryWriter?: { write: jest.Mock; emitHistoryAppended: jest.Mock };
  moderationEmailNotifier?: { notify: jest.Mock };
}) {
  const upload = deps.upload ?? {
    assertMediaUrlsFromOurBucket: jest.fn(),
    signUrls: jest.fn(async (urls: string[]) => urls),
  };
  const query = deps.query ?? {
    listForSite: jest.fn().mockResolvedValue({ data: [], meta: { page: 1, limit: 20, total: 0 } }),
  };
  const siteHistoryWriter = deps.siteHistoryWriter ?? {
    write: jest.fn(),
    emitHistoryAppended: jest.fn(),
  };
  const moderationEmailNotifier = deps.moderationEmailNotifier ?? {
    notify: jest.fn(),
  };

  return {
    service: new SiteResolutionSubmitService(
      deps.prisma as never,
      upload as never,
      query as never,
      siteHistoryWriter as never,
      moderationEmailNotifier as never,
    ),
    upload,
    query,
    siteHistoryWriter,
    moderationEmailNotifier,
  };
}

describe('SiteResolutionSubmitService', () => {
  const user = {
    userId: USER_ID,
    email: 'citizen@example.test',
    phoneNumber: '+38970123456',
    role: 'USER' as const,
  };

  const dto = {
    mediaUrls: ['https://cdn.example.test/photo1.jpg'],
    note: 'All clean now',
  };

  it('notifies admins by email after successful submission', async () => {
    const createdAt = new Date('2026-06-15T10:00:00.000Z');
    const resolution = {
      id: RESOLUTION_ID,
      siteId: SITE_ID,
      status: 'PENDING',
      mediaUrls: dto.mediaUrls,
      note: dto.note,
      isReporterSubmission: true,
      createdAt,
      submittedById: USER_ID,
      submittedBy: { firstName: 'Ana', lastName: 'Citizen', status: 'ACTIVE' },
    };

    const prisma: any = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          id: SITE_ID,
          status: SiteStatus.VERIFIED,
          address: 'City Park, Skopje',
          latitude: 41.9981,
          longitude: 21.4254,
        }),
      },
      siteResolution: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => {
        const tx: any = {
          report: { findFirst: jest.fn().mockResolvedValue({ id: 'report-1' }) },
          siteResolution: { create: jest.fn().mockResolvedValue(resolution) },
          adminNotification: { create: jest.fn().mockResolvedValue({ id: 'n1' }) },
        };
        return fn(tx);
      }),
    };

    const { service, moderationEmailNotifier } = createSubmitService({ prisma });

    await service.submit(SITE_ID, user, dto);

    expect(moderationEmailNotifier.notify).toHaveBeenCalledTimes(1);
    expect(moderationEmailNotifier.notify).toHaveBeenCalledWith({
      category: AdminModerationCategory.SITE_RESOLUTION,
      resourceId: RESOLUTION_ID,
      deepLinkPath: `/dashboard/sites/${SITE_ID}`,
      emailContext: expect.objectContaining({
        address: 'City Park, Skopje',
        latitude: 41.9981,
        longitude: 21.4254,
        siteStatus: SiteStatus.VERIFIED,
        submitterName: 'Ana Citizen',
        submitterEmail: user.email,
        isReporterSubmission: true,
        photoCount: 1,
        notePreview: dto.note,
        submittedAt: createdAt.toISOString(),
      }),
    });
  });

  it('does not notify when site is not found', async () => {
    const prisma: any = {
      site: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const { service, moderationEmailNotifier } = createSubmitService({ prisma });

    await expect(service.submit(SITE_ID, user, dto)).rejects.toBeInstanceOf(NotFoundException);
    expect(moderationEmailNotifier.notify).not.toHaveBeenCalled();
  });

  it('does not notify when a pending resolution already exists', async () => {
    const prisma: any = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          id: SITE_ID,
          status: SiteStatus.VERIFIED,
          address: null,
          latitude: 41.99,
          longitude: 21.43,
        }),
      },
      siteResolution: {
        findFirst: jest.fn().mockResolvedValue({ id: 'existing-pending' }),
      },
    };
    const { service, moderationEmailNotifier } = createSubmitService({ prisma });

    await expect(service.submit(SITE_ID, user, dto)).rejects.toBeInstanceOf(BadRequestException);
    expect(moderationEmailNotifier.notify).not.toHaveBeenCalled();
  });

  it('does not notify when site status disallows resolution submission', async () => {
    const prisma: any = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          id: SITE_ID,
          status: SiteStatus.REPORTED,
          address: null,
          latitude: 41.99,
          longitude: 21.43,
        }),
      },
    };
    const { service, moderationEmailNotifier } = createSubmitService({ prisma });

    await expect(service.submit(SITE_ID, user, dto)).rejects.toBeInstanceOf(BadRequestException);
    expect(moderationEmailNotifier.notify).not.toHaveBeenCalled();
  });
});

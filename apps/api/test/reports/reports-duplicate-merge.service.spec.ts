/// <reference types="jest" />
import { ReportSideEffectKind, ReportSideEffectStatus, Role } from '../../src/prisma-client';
import { DuplicateGroupQueryService } from '../../src/reports/duplicates/duplicate-group-query.service';
import { DuplicateMergeSideEffectsService } from '../../src/reports/duplicates/duplicate-merge-side-effects.service';
import { ReportSideEffectProcessorService } from '../../src/reports/side-effects/report-side-effect-processor.service';
import { ReportsDuplicateMergeService } from '../../src/reports/reports-duplicate-merge.service';

function createMergeServiceWithMocks(
  prisma: unknown,
  reportsUploadService: unknown,
  reportEvents: unknown,
  siteEvents: unknown,
  reportsOwnerEvents: unknown,
  eventEmitter: unknown,
): {
  service: ReportsDuplicateMergeService;
  reportApprovalPoints: { creditApprovalIfEligible: jest.Mock };
} {
  const duplicateGroupQuery = new DuplicateGroupQueryService(prisma as never);
  const audit = { log: jest.fn().mockResolvedValue(undefined) };
  const duplicateMergeSideEffects = new DuplicateMergeSideEffectsService(
    prisma as never,
    audit as never,
    reportsUploadService as never,
    reportEvents as never,
    siteEvents as never,
    reportsOwnerEvents as never,
    eventEmitter as never,
  );
  const reportSideEffectProcessor = new ReportSideEffectProcessorService(
    prisma as never,
    duplicateMergeSideEffects,
    audit as never,
    reportEvents as never,
    siteEvents as never,
    reportsOwnerEvents as never,
    eventEmitter as never,
  );
  const reportApprovalPoints = {
    creditApprovalIfEligible: jest.fn().mockResolvedValue({ awarded: 0, preCapTotal: 0 }),
  };
  const service = new ReportsDuplicateMergeService(
    prisma as never,
    duplicateGroupQuery,
    reportApprovalPoints as never,
    reportSideEffectProcessor,
  );
  return { service, reportApprovalPoints };
}

describe('ReportsDuplicateMergeService mergeDuplicateReports', () => {
  it('does not append child media to primary; hard-deletes children; deletes duplicate media from storage', async () => {
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const primaryId = 'primary-1';
    const childId = 'child-1';
    const childMedia = ['https://test-bucket.s3.eu-central-1.amazonaws.com/reports/u1/a.jpg'];

    const txReportUpdate = jest.fn();
    const txReportDeleteMany = jest.fn().mockResolvedValue({ count: 1 });
    const txReportUpdateMany = jest.fn().mockResolvedValue({ count: 0 });
    const txReportCoReporterUpsert = jest.fn();
    const txReportCount = jest.fn().mockResolvedValue(2);

    const mergePayload = {
      id: primaryId,
      siteId: 'site-1',
      status: 'NEW' as const,
      reporterId: 'user-a',
      reportNumber: 'CH-000001',
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      mediaUrls: ['https://test-bucket.s3.eu-central-1.amazonaws.com/reports/u-a/orig.jpg'],
      coReporters: [] as { userId: string }[],
      potentialDuplicates: [
        {
          id: childId,
          reporterId: 'user-b',
          createdAt: new Date('2026-01-02T00:00:00.000Z'),
          mediaUrls: childMedia,
          coReporters: [] as { userId: string; createdAt: Date }[],
        },
      ],
    };

    let findUniqueCalls = 0;
    let lastMergeSideEffect: {
      id: string;
      kind: typeof ReportSideEffectKind.MERGE_DUPLICATE_POST;
      status: ReportSideEffectStatus;
      payload: unknown;
    } | null = null;
    const prisma: any = {
      reportSideEffect: {
        findUnique: jest.fn(({ where }: { where: { id: string } }) => {
          if (lastMergeSideEffect && where.id === lastMergeSideEffect.id) {
            return Promise.resolve(lastMergeSideEffect);
          }
          return Promise.resolve(null);
        }),
        update: jest.fn().mockResolvedValue({}),
      },
      report: {
        findUnique: jest.fn().mockImplementation(() => {
          findUniqueCalls += 1;
          if (findUniqueCalls === 1) {
            return Promise.resolve({ id: primaryId, potentialDuplicateOfId: null });
          }
          if (findUniqueCalls === 2) {
            return Promise.resolve(mergePayload);
          }
          if (findUniqueCalls === 3) {
            return Promise.resolve({
              reporterId: 'user-a',
              coReporters: [{ userId: 'user-b' }],
            });
          }
          return Promise.resolve(null);
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          status: 'APPROVED',
          reporterId: 'user-a',
          coReporters: [
            {
              userId: 'user-b',
              reportedAt: new Date('2026-01-02T00:00:00.000Z'),
              user: { firstName: 'B', lastName: 'User' },
            },
          ],
        }),
      },
      $transaction: jest.fn(async (cb: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          report: {
            update: txReportUpdate,
            updateMany: txReportUpdateMany,
            deleteMany: txReportDeleteMany,
            count: txReportCount,
            findUniqueOrThrow: jest.fn().mockResolvedValue({
              id: primaryId,
              reporterId: 'user-a',
              siteId: 'site-1',
              mediaUrls: mergePayload.mediaUrls,
              severity: null,
              cleanupEffort: null,
            }),
          },
          reportCoReporter: {
            upsert: txReportCoReporterUpsert,
          },
          reportSideEffect: {
            create: jest.fn(({ data }: { data: { kind: string; status: string; payload: unknown } }) => {
              lastMergeSideEffect = {
                id: 'merge-effect-1',
                kind: data.kind as typeof ReportSideEffectKind.MERGE_DUPLICATE_POST,
                status: data.status as ReportSideEffectStatus,
                payload: data.payload,
              };
              return Promise.resolve({ id: 'merge-effect-1' });
            }),
          },
          site: {
            findUnique: jest.fn(),
            update: jest.fn(),
          },
        };
        return cb(tx);
      }),
    };

    const reportsUploadService = {
      signUrls: jest.fn(),
      deleteReportMediaUrls: jest.fn().mockResolvedValue(1),
      tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    };

    const reportsOwnerEvents = { emit: jest.fn(), emitToReportInterestedParties: jest.fn() };
    const eventEmitter = { emit: jest.fn() };

    const { service, reportApprovalPoints } = createMergeServiceWithMocks(
      prisma,
      reportsUploadService,
      { emitReportStatusUpdated: jest.fn() },
      { emitSiteUpdated: jest.fn() },
      reportsOwnerEvents,
      eventEmitter,
    );

    const result = await service.mergeDuplicateReports(
      primaryId,
      { childReportIds: [childId], reason: 'test' },
      moderator as never,
    );

    expect(reportsOwnerEvents.emitToReportInterestedParties).toHaveBeenCalledWith(
      primaryId,
      'user-a',
      ['user-b'],
      'report_updated',
      { kind: 'merged', status: 'APPROVED' },
    );

    expect(txReportUpdate).toHaveBeenCalledWith({
      where: { id: primaryId },
      data: expect.objectContaining({
        mergedDuplicateChildCount: { increment: 1 },
      }),
    });
    expect(txReportUpdate).toHaveBeenCalledWith({
      where: { id: primaryId },
      data: expect.not.objectContaining({
        mediaUrls: expect.anything(),
      }),
    });
    expect(txReportDeleteMany).toHaveBeenCalledWith({
      where: { id: { in: [childId] } },
    });
    expect(reportsUploadService.deleteReportMediaUrls).toHaveBeenCalledWith(childMedia);
    expect(result.reporterCount).toBe(2);
    expect(result.coReporters).toHaveLength(1);
    expect(result.coReporters[0].userId).toBe('user-b');
    expect(result.mergedMediaCount).toBe(1);
    expect(txReportCoReporterUpsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          reportId: primaryId,
          userId: 'user-b',
          reportedAt: mergePayload.potentialDuplicates[0].createdAt,
        }),
      }),
    );

    expect(reportApprovalPoints.creditApprovalIfEligible).toHaveBeenCalledTimes(1);

    const notificationSends = eventEmitter.emit.mock.calls.filter((c) => c[0] === 'notification.send');
    expect(notificationSends).toHaveLength(2);
    expect(notificationSends[0][1]).toMatchObject({
      recipientUserIds: ['user-a'],
      type: 'REPORT_STATUS',
      data: expect.objectContaining({
        mergeRole: 'primary',
        reportId: primaryId,
        siteId: 'site-1',
        reportNumber: 'CH-000001',
      }),
    });
    expect(notificationSends[1][1]).toMatchObject({
      recipientUserIds: ['user-b'],
      type: 'REPORT_STATUS',
      data: expect.objectContaining({
        mergeRole: 'merged_child',
        reportId: primaryId,
        siteId: 'site-1',
      }),
    });
  });

  it('is idempotent when child reports were already removed (no duplicate co-reporter rows on retry)', async () => {
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const primaryId = 'primary-1';
    const childId = 'child-1';

    let findCall = 0;
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockImplementation(() => {
          findCall += 1;
          if (findCall === 1) {
            return Promise.resolve({ id: primaryId, potentialDuplicateOfId: null });
          }
          return Promise.resolve({
            id: primaryId,
            siteId: 'site-1',
            status: 'APPROVED',
            reporterId: 'user-a',
            mediaUrls: [],
            coReporters: [],
            potentialDuplicates: [],
          });
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          status: 'APPROVED',
          reporterId: 'user-a',
          coReporters: [],
        }),
        count: jest.fn().mockResolvedValue(0),
      },
      $transaction: jest.fn(),
    };

    const reportsUploadService = {
      signUrls: jest.fn(),
      deleteReportMediaUrls: jest.fn(),
      tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    };

    const eventEmitter = { emit: jest.fn() };

    const { service } = createMergeServiceWithMocks(
      prisma,
      reportsUploadService,
      { emitReportStatusUpdated: jest.fn() },
      { emitSiteUpdated: jest.fn() },
      { emit: jest.fn() },
      eventEmitter,
    );

    const result = await service.mergeDuplicateReports(
      primaryId,
      { childReportIds: [childId] },
      moderator as never,
    );

    expect(result.mergedChildCount).toBe(0);
    expect(result.primaryReportId).toBe(primaryId);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(reportsUploadService.deleteReportMediaUrls).not.toHaveBeenCalled();
    expect(eventEmitter.emit.mock.calls.filter((c) => c[0] === 'notification.send')).toHaveLength(0);
  });

  it('notifies co-reporter-only users credited on merge (not duplicate of child reporter)', async () => {
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const primaryId = 'primary-1';
    const childId = 'child-1';
    const coOnlyUserId = 'user-co-only';

    const mergePayload = {
      id: primaryId,
      siteId: 'site-1',
      status: 'NEW' as const,
      reporterId: 'user-a',
      reportNumber: 'CH-000099',
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      mediaUrls: [],
      coReporters: [] as { userId: string }[],
      potentialDuplicates: [
        {
          id: childId,
          reporterId: null,
          createdAt: new Date('2026-01-02T00:00:00.000Z'),
          mediaUrls: [] as string[],
          coReporters: [
            { userId: coOnlyUserId, createdAt: new Date('2026-01-02T12:00:00.000Z') },
          ],
        },
      ],
    };

    let findUniqueCalls = 0;
    let lastMergeSideEffect: {
      id: string;
      kind: typeof ReportSideEffectKind.MERGE_DUPLICATE_POST;
      status: ReportSideEffectStatus;
      payload: unknown;
    } | null = null;
    const prisma: any = {
      reportSideEffect: {
        findUnique: jest.fn(({ where }: { where: { id: string } }) => {
          if (lastMergeSideEffect && where.id === lastMergeSideEffect.id) {
            return Promise.resolve(lastMergeSideEffect);
          }
          return Promise.resolve(null);
        }),
        update: jest.fn().mockResolvedValue({}),
      },
      report: {
        findUnique: jest.fn().mockImplementation(() => {
          findUniqueCalls += 1;
          if (findUniqueCalls === 1) {
            return Promise.resolve({ id: primaryId, potentialDuplicateOfId: null });
          }
          if (findUniqueCalls === 2) {
            return Promise.resolve(mergePayload);
          }
          if (findUniqueCalls === 3) {
            return Promise.resolve({
              reporterId: 'user-a',
              coReporters: [{ userId: coOnlyUserId }],
            });
          }
          return Promise.resolve(null);
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          status: 'APPROVED',
          reporterId: 'user-a',
          coReporters: [
            {
              userId: coOnlyUserId,
              reportedAt: new Date('2026-01-02T12:00:00.000Z'),
              user: { firstName: 'Co', lastName: 'Only' },
            },
          ],
        }),
      },
      $transaction: jest.fn(async (cb: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          report: {
            update: jest.fn(),
            updateMany: jest.fn().mockResolvedValue({ count: 0 }),
            deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
            count: jest.fn().mockResolvedValue(2),
            findUniqueOrThrow: jest.fn().mockResolvedValue({
              id: primaryId,
              reporterId: 'user-a',
              siteId: 'site-1',
              mediaUrls: [] as string[],
              severity: null,
              cleanupEffort: null,
            }),
          },
          reportCoReporter: {
            upsert: jest.fn(),
          },
          reportSideEffect: {
            create: jest.fn(({ data }: { data: { kind: string; status: string; payload: unknown } }) => {
              lastMergeSideEffect = {
                id: 'merge-effect-1',
                kind: data.kind as typeof ReportSideEffectKind.MERGE_DUPLICATE_POST,
                status: data.status as ReportSideEffectStatus,
                payload: data.payload,
              };
              return Promise.resolve({ id: 'merge-effect-1' });
            }),
          },
          site: {
            findUnique: jest.fn(),
            update: jest.fn(),
          },
        };
        return cb(tx);
      }),
    };

    const reportsUploadService = {
      signUrls: jest.fn(),
      deleteReportMediaUrls: jest.fn().mockResolvedValue(0),
      tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    };

    const reportsOwnerEvents = { emit: jest.fn(), emitToReportInterestedParties: jest.fn() };
    const eventEmitter = { emit: jest.fn() };

    const { service, reportApprovalPoints } = createMergeServiceWithMocks(
      prisma,
      reportsUploadService,
      { emitReportStatusUpdated: jest.fn() },
      { emitSiteUpdated: jest.fn() },
      reportsOwnerEvents,
      eventEmitter,
    );

    await service.mergeDuplicateReports(
      primaryId,
      { childReportIds: [childId], reason: 'test' },
      moderator as never,
    );

    expect(reportApprovalPoints.creditApprovalIfEligible).toHaveBeenCalledTimes(1);

    expect(reportsOwnerEvents.emitToReportInterestedParties).toHaveBeenCalledWith(
      primaryId,
      'user-a',
      [coOnlyUserId],
      'report_updated',
      { kind: 'merged', status: 'APPROVED' },
    );

    const notificationSends = eventEmitter.emit.mock.calls.filter((c) => c[0] === 'notification.send');
    expect(notificationSends).toHaveLength(2);
    const roles = notificationSends.map((c) => (c[1] as { data: { mergeRole: string } }).data.mergeRole).sort();
    expect(roles).toEqual(['co_reporter_credited', 'primary']);
  });
});

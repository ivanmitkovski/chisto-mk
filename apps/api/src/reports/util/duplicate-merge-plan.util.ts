import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import type { MergeDuplicateSideEffectPayload } from '../side-effects/report-side-effect-processor.service';
import type { SiteStatus } from '../../prisma-client';

type MergeChild = {
  id: string;
  reporterId: string | null;
  createdAt: Date;
  mediaUrls: string[];
  coReporters: Array<{ userId: string | null; createdAt: Date }>;
};

type MergePrimary = {
  id: string;
  siteId: string;
  reporterId: string | null;
  reportNumber: string | null;
  createdAt: Date;
  mediaUrls: string[];
  coReporters: Array<{ userId: string | null }>;
};

/**
 * Plans which child reporters/co-reporters become new co-reporters of the
 * primary report, keeping the earliest attribution per user and excluding
 * the primary reporter and already-attached co-reporters.
 */
export function planMergedCoReporters(
  primaryReport: Pick<MergePrimary, 'reporterId' | 'coReporters'>,
  selectedChildren: MergeChild[],
): { plannedNewCoReporterIds: string[]; coReporterReportedAt: Map<string, Date> } {
  const currentCoReporterIds = new Set(primaryReport.coReporters.map((c) => c.userId));
  const coReporterReportedAt = new Map<string, Date>();
  const primaryReporterId = primaryReport.reporterId;

  const offerCoReporter = (userId: string | null | undefined, reportedAt: Date) => {
    if (!userId || userId === primaryReporterId) {
      return;
    }
    const prev = coReporterReportedAt.get(userId);
    if (!prev || reportedAt < prev) {
      coReporterReportedAt.set(userId, reportedAt);
    }
  };

  for (const child of selectedChildren) {
    offerCoReporter(child.reporterId, child.createdAt);
    for (const coReporter of child.coReporters) {
      offerCoReporter(coReporter.userId, coReporter.createdAt);
    }
  }

  const plannedNewCoReporterIds = [...coReporterReportedAt.keys()].filter(
    (userId) => !currentCoReporterIds.has(userId),
  );
  return { plannedNewCoReporterIds, coReporterReportedAt };
}

export function buildMergeSideEffectPayload(args: {
  moderator: AuthenticatedUser;
  primaryReport: MergePrimary;
  selectedChildIds: string[];
  selectedChildren: MergeChild[];
  plannedNewCoReporterIds: string[];
  duplicateMediaUrls: string[];
  siteStatusEvent: {
    id: string;
    status: SiteStatus;
    latitude: number;
    longitude: number;
    updatedAt: Date;
  } | null;
}): MergeDuplicateSideEffectPayload {
  const { moderator, primaryReport, siteStatusEvent } = args;
  return {
    moderator,
    primaryReport: {
      id: primaryReport.id,
      siteId: primaryReport.siteId,
      reporterId: primaryReport.reporterId,
      reportNumber: primaryReport.reportNumber,
      createdAt: primaryReport.createdAt.toISOString(),
      mediaUrls: primaryReport.mediaUrls,
    },
    selectedChildIds: args.selectedChildIds,
    selectedChildren: args.selectedChildren.map((c) => ({
      id: c.id,
      reporterId: c.reporterId,
    })),
    plannedNewCoReporterIds: args.plannedNewCoReporterIds,
    duplicateMediaUrls: args.duplicateMediaUrls,
    siteStatusEvent:
      siteStatusEvent == null
        ? null
        : {
            id: siteStatusEvent.id,
            status: siteStatusEvent.status,
            latitude: siteStatusEvent.latitude,
            longitude: siteStatusEvent.longitude,
            updatedAt: siteStatusEvent.updatedAt.toISOString(),
          },
  };
}

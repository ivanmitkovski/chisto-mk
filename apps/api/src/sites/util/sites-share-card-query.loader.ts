import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  EventEvidenceKind,
  ReportStatus,
  SiteResolutionStatus,
  SiteStatus,
} from '../../prisma-client';
import type { PrismaService } from '../../prisma/prisma.service';
import type { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { SHARE_CARD_EVIDENCE_CAP, SHARE_CARD_EVENTS_CAP, pushUniqueUrls } from '../util/sites-share-card.helpers';

export const publicShareSiteSelect = {
  id: true,
  address: true,
  description: true,
  status: true,
  latitude: true,
  longitude: true,
  upvotesCount: true,
  commentsCount: true,
  sharesCount: true,
  savesCount: true,
  heroReport: {
    select: {
      title: true,
      description: true,
      mediaUrls: true,
      category: true,
      severity: true,
      cleanupEffort: true,
      createdAt: true,
      reporterId: true,
      reporter: {
        select: {
          firstName: true,
          lastName: true,
          avatarObjectKey: true,
          status: true,
        },
      },
    },
  },
  reports: {
    where: { status: ReportStatus.APPROVED },
    orderBy: { createdAt: 'asc' as const },
    take: 8,
    select: {
      title: true,
      description: true,
      mediaUrls: true,
      category: true,
      severity: true,
      cleanupEffort: true,
      createdAt: true,
      reporterId: true,
      reporter: {
        select: {
          firstName: true,
          lastName: true,
          avatarObjectKey: true,
          status: true,
        },
      },
    },
  },
  events: {
    where: {
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: {
        in: [EcoEventLifecycleStatus.UPCOMING, EcoEventLifecycleStatus.IN_PROGRESS],
      },
    },
    orderBy: { scheduledAt: 'asc' as const },
    take: SHARE_CARD_EVENTS_CAP,
    select: {
      id: true,
      title: true,
      scheduledAt: true,
      participantCount: true,
      maxParticipants: true,
      lifecycleStatus: true,
    },
  },
  resolutions: {
    where: { status: SiteResolutionStatus.APPROVED },
    orderBy: { createdAt: 'asc' as const },
    take: 6,
    select: { mediaUrls: true },
  },
};

export async function findPublicShareSiteRow(prisma: PrismaService, id: string) {
  return prisma.site.findFirst({
    where: {
      id,
      status: { not: SiteStatus.REPORTED },
      isArchivedByAdmin: false,
    },
    select: publicShareSiteSelect,
  });
}

export async function collectCleanupEvidenceUrls(
  prisma: PrismaService,
  reportsUpload: Pick<ReportsUploadService, 'getPublicUrlsForKeys'>,
  siteId: string,
  resolutions: { mediaUrls: string[] }[],
): Promise<string[]> {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const resolution of resolutions) {
    pushUniqueUrls(out, seen, resolution.mediaUrls ?? [], SHARE_CARD_EVIDENCE_CAP);
    if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;
  }

  const events = await prisma.cleanupEvent.findMany({
    where: { siteId },
    select: {
      afterImageKeys: true,
      evidencePhotos: {
        where: { kind: EventEvidenceKind.AFTER },
        select: { objectKey: true },
        take: SHARE_CARD_EVIDENCE_CAP,
      },
    },
    take: 20,
  });

  for (const event of events) {
    const fromKeys = event.afterImageKeys.map(
      (key) => reportsUpload.getPublicUrlsForKeys([key])[0] ?? key,
    );
    pushUniqueUrls(out, seen, fromKeys, SHARE_CARD_EVIDENCE_CAP);
    if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;

    const fromPhotos = event.evidencePhotos.map(
      (photo) => reportsUpload.getPublicUrlsForKeys([photo.objectKey])[0] ?? photo.objectKey,
    );
    pushUniqueUrls(out, seen, fromPhotos, SHARE_CARD_EVIDENCE_CAP);
    if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;
  }

  return out;
}

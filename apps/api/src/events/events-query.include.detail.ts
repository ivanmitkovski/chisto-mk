import { Prisma, ReportStatus } from '../prisma-client';
import { noCheckInRows, noParticipantRows } from './events-query.include.shared';

/**
 * Full Prisma include for cleanup events (detail, mutations, participation, check-in).
 */
export const eventDetailIncludeForViewer = (viewerId?: string) =>
  ({
    site: {
      select: {
        id: true,
        address: true,
        description: true,
        latitude: true,
        longitude: true,
        reports: {
          where: {
            status: { not: ReportStatus.DELETED },
            mediaUrls: { isEmpty: false },
          },
          take: 1,
          orderBy: { createdAt: 'asc' },
          select: { mediaUrls: true },
        },
      },
    },
    organizer: {
      select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
    },
    participants: {
      where:
        viewerId != null && viewerId !== ''
          ? { userId: viewerId }
          : noParticipantRows,
      take: 1,
      select: { id: true, reminderEnabled: true, reminderAt: true },
    },
    checkIns: {
      where:
        viewerId != null && viewerId !== '' ? { userId: viewerId } : noCheckInRows,
      take: 1,
      select: { checkedInAt: true },
    },
    liveMetric: {
      select: { reportedBagsCollected: true, updatedAt: true },
    },
    routeSegments: {
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        sortOrder: true,
        label: true,
        latitude: true,
        longitude: true,
        status: true,
        claimedByUserId: true,
        claimedAt: true,
        completedAt: true,
      },
    },
    evidencePhotos: {
      orderBy: { createdAt: 'asc' },
      take: 32,
      select: {
        id: true,
        kind: true,
        objectKey: true,
        caption: true,
        createdAt: true,
      },
    },
  }) satisfies Prisma.CleanupEventInclude;

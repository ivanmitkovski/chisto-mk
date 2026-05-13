import { Prisma, ReportStatus } from '../prisma-client';
import { noCheckInRows, noParticipantRows } from './events-query.include.shared';

/**
 * Lighter include for list + ranked search: omits route segments and evidence strip
 * (still maps via {@link EventsMobileMapperService.toMobileEvent} with empty arrays).
 */
export const eventListIncludeForViewer = (viewerId?: string) =>
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
  }) satisfies Prisma.CleanupEventInclude;

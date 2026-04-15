import { CleanupEventStatus, Prisma, ReportStatus } from '../prisma-client';

const noParticipantRows: Prisma.EventParticipantWhereInput = { id: { in: [] } };
const noCheckInRows: Prisma.EventCheckInWhereInput = { id: { in: [] } };

export const eventIncludeForViewer = (viewerId?: string) =>
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
  }) satisfies Prisma.CleanupEventInclude;

export type LoadedEvent = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventIncludeForViewer>;
}>;

export function visibilityWhere(viewerUserId?: string): Prisma.CleanupEventWhereInput {
  if (viewerUserId == null || viewerUserId === '') {
    return { status: CleanupEventStatus.APPROVED };
  }
  return {
    OR: [{ status: CleanupEventStatus.APPROVED }, { organizerId: viewerUserId }],
  };
}

export function participantDisplayName(user: {
  firstName: string;
  lastName: string;
}): string {
  return `${user.firstName} ${user.lastName}`.trim();
}

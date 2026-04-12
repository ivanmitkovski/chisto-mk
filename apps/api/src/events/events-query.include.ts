import { CleanupEventStatus, Prisma, ReportStatus } from '../prisma-client';

export const eventIncludeForViewer = (viewerId: string) =>
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
      where: { userId: viewerId },
      take: 1,
      select: { id: true, reminderEnabled: true, reminderAt: true },
    },
    checkIns: {
      where: { userId: viewerId },
      take: 1,
      select: { checkedInAt: true },
    },
  }) satisfies Prisma.CleanupEventInclude;

export type LoadedEvent = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventIncludeForViewer>;
}>;

export function visibilityWhere(userId: string): Prisma.CleanupEventWhereInput {
  return {
    OR: [{ status: CleanupEventStatus.APPROVED }, { organizerId: userId }],
  };
}

export function participantDisplayName(user: {
  firstName: string;
  lastName: string;
}): string {
  return `${user.firstName} ${user.lastName}`.trim();
}

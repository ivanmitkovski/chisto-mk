import { CleanupEventStatus, Prisma } from '../prisma-client';

export const noParticipantRows: Prisma.EventParticipantWhereInput = { id: { in: [] } };
export const noCheckInRows: Prisma.EventCheckInWhereInput = { id: { in: [] } };

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

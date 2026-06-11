import { CleanupEventStatus, Prisma } from '../../prisma-client';
import { participantDisplayName as resolveParticipantDisplayName } from '../../common/projections/public-identity.projection';

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

export function participantDisplayName(
  user: { firstName: string; lastName: string; status?: import('../../prisma-client').UserStatus } | null,
  options?: { actorUserId?: string | null; fallback?: string },
): string {
  return resolveParticipantDisplayName(user, options).displayName;
}

export function participantDisplayIdentity(
  user: { firstName: string; lastName: string; status?: import('../../prisma-client').UserStatus } | null,
  options?: { actorUserId?: string | null; fallback?: string },
): { displayName: string; isDeleted: boolean } {
  return resolveParticipantDisplayName(user, options);
}

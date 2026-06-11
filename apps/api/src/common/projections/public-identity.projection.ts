import { Role, UserStatus } from '../../prisma-client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

export type ActorIdentityUser = {
  firstName: string;
  lastName: string;
  status?: UserStatus;
};

export type ResolvedActorIdentity = {
  displayName: string | null;
  isDeleted: boolean;
  isAnonymous: boolean;
};

export type PublicReporterView = {
  displayLabel: string | null;
  isSelf: boolean;
  isDeleted: boolean;
  isAnonymous: boolean;
};

/**
 * Resolves a civic actor's public display identity.
 * Deleted when the user row is missing (hard purge) or status is DELETED (soft erase).
 */
export function resolveActorIdentity(
  user: ActorIdentityUser | null | undefined,
  options?: { actorUserId?: string | null },
): ResolvedActorIdentity {
  const actorUserId = options?.actorUserId ?? null;
  if (user == null) {
    if (actorUserId != null) {
      return { displayName: null, isDeleted: true, isAnonymous: false };
    }
    return { displayName: 'Anonymous', isDeleted: false, isAnonymous: true };
  }
  if (user.status === UserStatus.DELETED) {
    return { displayName: null, isDeleted: true, isAnonymous: false };
  }
  const fullName = `${user.firstName} ${user.lastName}`.trim();
  if (fullName.length === 0) {
    return { displayName: 'Anonymous', isDeleted: false, isAnonymous: true };
  }
  return { displayName: fullName, isDeleted: false, isAnonymous: false };
}

/** Full reporter name for site detail (reporter row, hero, co-reporters). */
export function projectPublicReporter(
  reporterId: string | null,
  reporter: ActorIdentityUser | null,
  viewer: AuthenticatedUser | undefined,
  _isModerator: boolean,
): PublicReporterView | null {
  if (reporterId == null && reporter == null) {
    return null;
  }
  const identity = resolveActorIdentity(reporter, { actorUserId: reporterId });
  return {
    displayLabel: identity.displayName,
    isSelf: reporterId != null && viewer?.userId === reporterId,
    isDeleted: identity.isDeleted,
    isAnonymous: identity.isAnonymous,
  };
}

export function viewerIsModerator(role: Role | undefined): boolean {
  return role === Role.ADMIN || role === Role.SUPER_ADMIN || role === Role.SUPPORT;
}

export type LeaderboardIdentity = { displayLabel: string; userId?: string; isDeleted?: boolean };

export function projectLeaderboardIdentity(
  user: {
    id: string;
    firstName: string;
    lastName: string;
    showOnLeaderboard: boolean;
    status?: UserStatus;
  },
  viewerId?: string,
): LeaderboardIdentity {
  const identity = resolveActorIdentity(user);
  if (identity.isDeleted) {
    return { displayLabel: identity.displayName ?? 'Anonymous', isDeleted: true };
  }
  if (!user.showOnLeaderboard && user.id !== viewerId) {
    return { displayLabel: 'Anonymous' };
  }
  const entry: LeaderboardIdentity = {
    displayLabel: identity.displayName ?? 'Anonymous',
  };
  if (user.showOnLeaderboard) entry.userId = user.id;
  return entry;
}

export function projectSelfIdentity(user: {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  status?: UserStatus;
}): { id: string; displayName: string; email?: string } {
  const identity = resolveActorIdentity(user, { actorUserId: user.id });
  const out: { id: string; displayName: string; email?: string } = {
    id: user.id,
    displayName: identity.displayName ?? '',
  };
  if (user.email) out.email = user.email;
  return out;
}

export function participantDisplayName(
  user: ActorIdentityUser | null | undefined,
  options?: { actorUserId?: string | null; fallback?: string },
): { displayName: string; isDeleted: boolean } {
  const identity = resolveActorIdentity(user, options);
  if (identity.isDeleted) {
    return { displayName: '', isDeleted: true };
  }
  return {
    displayName: identity.displayName ?? options?.fallback ?? 'Anonymous',
    isDeleted: false,
  };
}

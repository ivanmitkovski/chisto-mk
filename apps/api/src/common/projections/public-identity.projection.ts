import { Role } from '../../prisma-client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

export type PublicReporterView = {
  displayLabel: string;
  isSelf: boolean;
};

/** Redact reporter identity for public site detail (non-moderator). */
export function projectPublicReporter(
  reporter: { userId: string; firstName: string; lastName: string } | null,
  viewer: AuthenticatedUser | undefined,
  isModerator: boolean,
): PublicReporterView | null {
  if (!reporter) return null;
  if (isModerator || viewer?.userId === reporter.userId) {
    return {
      displayLabel: `${reporter.firstName} ${reporter.lastName}`.trim(),
      isSelf: viewer?.userId === reporter.userId,
    };
  }
  const initial = reporter.firstName.trim().charAt(0) || '?';
  return {
    displayLabel: `${initial}.`,
    isSelf: false,
  };
}

export function viewerIsModerator(role: Role | undefined): boolean {
  return role === Role.ADMIN || role === Role.SUPER_ADMIN || role === Role.SUPPORT;
}

export type LeaderboardIdentity = { displayLabel: string; userId?: string };

export function projectLeaderboardIdentity(
  user: { id: string; firstName: string; lastName: string; showOnLeaderboard: boolean },
  viewerId?: string,
): LeaderboardIdentity {
  if (!user.showOnLeaderboard && user.id !== viewerId) {
    return { displayLabel: 'Anonymous' };
  }
  const initial = user.firstName.trim().charAt(0) || '?';
  const entry: LeaderboardIdentity = {
    displayLabel: user.id === viewerId ? `${user.firstName} ${user.lastName}`.trim() : `${initial}.`,
  };
  if (user.showOnLeaderboard) entry.userId = user.id;
  return entry;
}

export function projectSelfIdentity(user: {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
}): { id: string; displayName: string; email?: string } {
  const out: { id: string; displayName: string; email?: string } = {
    id: user.id,
    displayName: `${user.firstName} ${user.lastName}`.trim(),
  };
  if (user.email) out.email = user.email;
  return out;
}

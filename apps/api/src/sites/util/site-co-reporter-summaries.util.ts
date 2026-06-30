import type { UserStatus } from '../../prisma-client';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

type CoReporterUser = {
  firstName: string;
  lastName: string;
  avatarUrl: string | null;
  status?: UserStatus;
};

type CoReporterRow = {
  userId: string | null;
  reportedAt: Date;
  user: CoReporterUser | null;
};

export type SiteCoReporterSummary = { userId: string; name: string; avatarUrl: string | null };

/**
 * Dedupes co-reporters across a site's reports, keeping the earliest
 * attribution and the richest display name/avatar per user.
 */
export function buildSiteCoReporterSummaries(
  reports: Array<{ coReporters: CoReporterRow[] }>,
): SiteCoReporterSummary[] {
  const anonymous = 'Anonymous';
  const pickRicher = (a: string, b: string): string => {
    if (a === anonymous && b !== anonymous) return b;
    if (b === anonymous && a !== anonymous) return a;
    return a;
  };
  const pickAvatar = (a: string | null, b: string | null): string | null => {
    const x = a?.trim() ?? '';
    const y = b?.trim() ?? '';
    if (x.length > 0) return x;
    if (y.length > 0) return y;
    return null;
  };
  const display = (
    userId: string,
    user: { firstName: string; lastName: string; status?: UserStatus } | null,
  ): string => {
    const identity = resolveActorIdentity(user, { actorUserId: userId });
    return identity.displayName ?? 'Anonymous';
  };
  const byUser = new Map<string, { name: string; reportedAt: Date; avatarUrl: string | null }>();
  for (const r of reports) {
    for (const cr of r.coReporters) {
      if (cr.userId == null) {
        continue;
      }
      const name = display(cr.userId, cr.user);
      const reportedAt = cr.reportedAt;
      const avatarUrl = cr.user?.avatarUrl?.trim() ? cr.user.avatarUrl : null;
      const prev = byUser.get(cr.userId);
      if (!prev) {
        byUser.set(cr.userId, { name, reportedAt, avatarUrl });
        continue;
      }
      const incomingEarlier = reportedAt < prev.reportedAt;
      const nextAt = incomingEarlier ? reportedAt : prev.reportedAt;
      const nextName = incomingEarlier ? pickRicher(name, prev.name) : pickRicher(prev.name, name);
      const nextAvatar = incomingEarlier
        ? pickAvatar(avatarUrl, prev.avatarUrl)
        : pickAvatar(prev.avatarUrl, avatarUrl);
      byUser.set(cr.userId, { name: nextName, reportedAt: nextAt, avatarUrl: nextAvatar });
    }
  }
  return [...byUser.entries()]
    .sort(([, av], [, bv]) => {
      if (av.reportedAt < bv.reportedAt) return -1;
      if (av.reportedAt > bv.reportedAt) return 1;
      return av.name.localeCompare(bv.name);
    })
    .map(([userId, v]) => ({ userId, name: v.name, avatarUrl: v.avatarUrl }));
}

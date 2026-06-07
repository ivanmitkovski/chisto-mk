import { cookies } from 'next/headers';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { ApiConnectionError, ApiError } from '@/lib/api';
import { can } from '@/lib/auth/rbac';
import { getMeProfile } from '@/features/auth';
import { getUserDetail, getUserAudit, getUserSessions } from '@/features/users';
import { getUserPointLedger } from '@/features/gamification';
import { UserDetailTabs } from '@/features/users';

type PageProps = { params: Promise<{ id: string }> };

export default async function UserDetailPage(props: PageProps) {
  const { id } = await props.params;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let user: Awaited<ReturnType<typeof getUserDetail>>;
  try {
    user = await getUserDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'USER_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    const message =
      error instanceof ApiConnectionError
        ? 'Unable to reach the API. Check your connection and try again.'
        : 'Unable to load user.';
    return (
      <AdminShell title="User" activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  if (!user || typeof user !== 'object') {
    notFound();
  }

  const u = user as {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: string;
    status: string;
    pointsBalance: number;
    totalPointsEarned: number;
    isPhoneVerified: boolean;
    organizerCertifiedAt: string | null;
    termsAcceptedAt: string | null;
    termsVersion: string | null;
    requiresTermsAcceptance: boolean;
    privacyAcceptedAt: string | null;
    createdAt: string;
    reportsCount: number;
    sessionsCount: number;
  };

  let audit: Awaited<ReturnType<typeof getUserAudit>>;
  let sessions: Awaited<ReturnType<typeof getUserSessions>>;
  let pointLedger: Awaited<ReturnType<typeof getUserPointLedger>>;
  let canViewSessions = false;
  let auditError: string | null = null;
  let sessionsError: string | null = null;
  let pointsError: string | null = null;

  try {
    const me = await getMeProfile();
    canViewSessions = can(me.role, 'users:write');
  } catch {
    canViewSessions = false;
  }

  try {
    audit = await getUserAudit(id, 1, 20);
  } catch (error) {
    audit = { data: [], meta: { page: 1, limit: 20, total: 0 } };
    auditError =
      error instanceof ApiConnectionError
        ? 'Unable to load audit history.'
        : 'Audit history could not be loaded.';
  }

  try {
    pointLedger = await getUserPointLedger(id, 20, 1);
  } catch (error) {
    pointLedger = { data: [], meta: { page: 1, limit: 20, total: 0 } };
    pointsError =
      error instanceof ApiConnectionError
        ? 'Unable to load points ledger.'
        : 'Points ledger could not be loaded.';
  }

  if (canViewSessions) {
    try {
      sessions = await getUserSessions(id);
    } catch (error) {
      sessions = [];
      sessionsError =
        error instanceof ApiConnectionError
          ? 'Unable to load sessions.'
          : 'Sessions could not be loaded.';
    }
  } else {
    sessions = [];
  }

  return (
    <AdminShell title={`${u.firstName} ${u.lastName}`} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <UserDetailTabs
        userId={u.id}
        initialFirstName={u.firstName}
        initialLastName={u.lastName}
        initialRole={u.role}
        initialStatus={u.status}
        initialPhoneNumber={u.phoneNumber ?? ''}
        email={u.email}
        pointsBalance={u.pointsBalance}
        totalPointsEarned={u.totalPointsEarned ?? 0}
        isPhoneVerified={u.isPhoneVerified ?? false}
        organizerCertifiedAt={u.organizerCertifiedAt ?? null}
        termsAcceptedAt={u.termsAcceptedAt ?? null}
        termsVersion={u.termsVersion ?? null}
        requiresTermsAcceptance={u.requiresTermsAcceptance ?? false}
        privacyAcceptedAt={u.privacyAcceptedAt ?? null}
        createdAt={u.createdAt}
        reportsCount={u.reportsCount}
        sessionsCount={u.sessionsCount}
        canViewSessions={canViewSessions}
        audit={audit}
        auditError={auditError}
        sessions={sessions}
        sessionsError={sessionsError}
        pointLedger={pointLedger.data}
        pointLedgerTotal={pointLedger.meta.total}
        pointLedgerPage={pointLedger.meta.page}
        pointLedgerLimit={pointLedger.meta.limit}
        pointsError={pointsError}
      />
    </AdminShell>
  );
}

import { notFound } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiConnectionError, ApiError } from '@/lib/api';
import { can } from '@/lib/auth/rbac';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import {
  getUserDetail,
  getUserAudit,
  getUserSessions,
  getUserSafetySummary,
  getUserActivityDetails,
  getUserModerationNotes,
  getUserStatusHistory,
} from '@/features/users';
import { getUserPointLedger } from '@/features/gamification';
import { UserDetailTabs } from '@/features/users';

type PageProps = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ safety?: string }>;
};

export default async function UserDetailPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['users:read']);
  const { id } = await props.params;
  const searchParams = await props.searchParams;
  const initialActiveTab = searchParams.safety === 'ugc' ? 'safety' : undefined;
  const tNav = await getTranslations('nav');
  const tErrors = await getTranslations('errors');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  let user: Awaited<ReturnType<typeof getUserDetail>>;
  try {
    user = await getUserDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'USER_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    const message =
      error instanceof ApiConnectionError
        ? tErrors('couldNotReachApi')
        : tErrors('unableToLoadUser');
    return (
      <AdminShell title={tNav('users')} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
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
    lastActiveAt: string | null;
    createdAt: string;
    reportsCount: number;
    sessionsCount: number;
    avatarUrl?: string | null;
  };

  let audit: Awaited<ReturnType<typeof getUserAudit>>;
  let sessions: Awaited<ReturnType<typeof getUserSessions>>;
  let pointLedger: Awaited<ReturnType<typeof getUserPointLedger>>;
  let safetySummary: Awaited<ReturnType<typeof getUserSafetySummary>> | null = null;
  let activityDetails: Awaited<ReturnType<typeof getUserActivityDetails>> | null = null;
  let canViewSessions = false;
  let auditError: string | null = null;
  let sessionsError: string | null = null;
  let pointsError: string | null = null;
  let safetyError: string | null = null;
  let activityError: string | null = null;

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
        ? tErrors('couldNotReachApi')
        : tErrors('unableToLoadAudit');
  }

  try {
    pointLedger = await getUserPointLedger(id, 20, 1);
  } catch (error) {
    pointLedger = { data: [], meta: { page: 1, limit: 20, total: 0 } };
    pointsError =
      error instanceof ApiConnectionError
        ? tErrors('couldNotReachApi')
        : tErrors('unableToLoadUserPoints');
  }

  let moderationNotes: Awaited<ReturnType<typeof getUserModerationNotes>> = {
    data: [],
    meta: { page: 1, limit: 20, total: 0 },
  };
  let statusHistory: Awaited<ReturnType<typeof getUserStatusHistory>> = {
    data: [],
    meta: { page: 1, limit: 20, total: 0 },
  };

  try {
    moderationNotes = await getUserModerationNotes(id, 1, 20);
  } catch {
    moderationNotes = { data: [], meta: { page: 1, limit: 20, total: 0 } };
  }

  try {
    statusHistory = await getUserStatusHistory(id, 1, 20);
  } catch {
    statusHistory = { data: [], meta: { page: 1, limit: 20, total: 0 } };
  }

  try {
    safetySummary = await getUserSafetySummary(id);
  } catch (error) {
    safetyError =
      error instanceof ApiConnectionError
        ? tErrors('couldNotReachApi')
        : tErrors('somethingWentWrongTryAgain');
  }

  try {
    activityDetails = await getUserActivityDetails(id);
  } catch (error) {
    activityError =
      error instanceof ApiConnectionError
        ? tErrors('couldNotReachApi')
        : tErrors('somethingWentWrongTryAgain');
  }

  if (canViewSessions) {
    try {
      sessions = await getUserSessions(id);
    } catch (error) {
      sessions = [];
      sessionsError =
        error instanceof ApiConnectionError
          ? tErrors('couldNotReachApi')
          : tErrors('unableToLoadUserSessions');
    }
  } else {
    sessions = [];
  }

  const displayName =
    u.status === 'DELETED'
      ? (await getTranslations('users'))('deletedUser')
      : `${u.firstName} ${u.lastName}`.trim();

  return (
    <AdminShell title={displayName} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <UserDetailTabs
        userId={u.id}
        initialFirstName={u.firstName}
        initialLastName={u.lastName}
        initialRole={u.role}
        initialStatus={u.status}
        initialPhoneNumber={u.phoneNumber ?? ''}
        email={u.email}
        avatarUrl={u.avatarUrl ?? null}
        lastActiveAt={u.lastActiveAt ?? null}
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
        safetySummary={safetySummary}
        safetyError={safetyError}
        moderationNotes={moderationNotes.data}
        statusHistory={statusHistory.data}
        activityDetails={activityDetails}
        activityError={activityError}
        audit={audit}
        auditError={auditError}
        sessions={sessions}
        sessionsError={sessionsError}
        pointLedger={pointLedger.data}
        pointLedgerTotal={pointLedger.meta.total}
        pointLedgerPage={pointLedger.meta.page}
        pointLedgerLimit={pointLedger.meta.limit}
        pointsError={pointsError}
        initialReportCreditsAvailable={
          (pointLedger as { reportCreditsAvailable?: number }).reportCreditsAvailable ?? 0
        }
        initialReportCreditsSpentTotal={
          (pointLedger as { reportCreditsSpentTotal?: number }).reportCreditsSpentTotal ?? 0
        }
        {...(initialActiveTab ? { initialActiveTab } : {})}
      />
    </AdminShell>
  );
}

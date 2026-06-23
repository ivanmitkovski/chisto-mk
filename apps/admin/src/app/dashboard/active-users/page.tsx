import { Suspense } from 'react';
import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiConnectionError } from '@/lib/api';
import { ActiveUsersWorkspace } from '@/features/active-users';
import {
  fetchActiveUsersList,
  fetchActiveUsersSummary,
  fetchAlertRules,
  fetchRealtimeAnalytics,
} from '@/features/active-users/data/active-users-adapter.server';
import { EMPTY_REALTIME_ANALYTICS } from '@/features/active-users/data/active-users.types';
import { ACTIVE_USERS_PAGE_SIZE } from '@/features/active-users/constants/active-users-filters';
import {
  ActiveUsersEngagementFallback,
  ActiveUsersEngagementSection,
  ActiveUsersGeoFallback,
  ActiveUsersGeoSection,
} from '@/features/active-users/components/active-users-async-sections';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

type SearchParams = Promise<{
  search?: string;
  status?: string;
  platform?: string;
  page?: string;
  feedType?: string;
}>;

function loadErrorMessage(
  error: unknown,
  tErrors: Awaited<ReturnType<typeof getTranslations<'errors'>>>,
): string {
  return error instanceof ApiConnectionError
    ? tErrors('couldNotReachApi')
    : tErrors('somethingWentWrongTryAgain');
}

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('activeUsers');
  return { title: t('pageTitle') };
}

export default async function ActiveUsersPage(props: { searchParams: SearchParams }) {
  const t = await getTranslations('activeUsers');
  const tErrors = await getTranslations('errors');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const sp = await props.searchParams;

  await requirePagePermission(ADMIN_PERMISSIONS['analytics:read']);

  const page = Math.max(1, Number(sp.page ?? '1') || 1);
  const listParams = new URLSearchParams({
    page: String(page),
    limit: String(ACTIVE_USERS_PAGE_SIZE),
  });
  if (sp.search) listParams.set('search', sp.search);
  if (sp.status) listParams.set('status', sp.status);
  if (sp.platform) listParams.set('platform', sp.platform);

  const loadErrors: {
    summary?: string;
    list?: string;
    realtime?: string;
    alerts?: string;
  } = {};

  const [summaryResult, listResult, realtimeResult, alertsResult] = await Promise.allSettled([
    fetchActiveUsersSummary(),
    fetchActiveUsersList(listParams),
    fetchRealtimeAnalytics(),
    fetchAlertRules(),
  ]);

  let summary: Awaited<ReturnType<typeof fetchActiveUsersSummary>> | null = null;
  if (summaryResult.status === 'fulfilled') {
    summary = summaryResult.value;
  } else {
    loadErrors.summary = loadErrorMessage(summaryResult.reason, tErrors);
  }

  let list: Awaited<ReturnType<typeof fetchActiveUsersList>> = { rows: [], total: 0 };
  if (listResult.status === 'fulfilled') {
    list = listResult.value;
  } else {
    loadErrors.list = loadErrorMessage(listResult.reason, tErrors);
  }

  let realtime = EMPTY_REALTIME_ANALYTICS;
  if (realtimeResult.status === 'fulfilled') {
    realtime = realtimeResult.value;
  } else {
    loadErrors.realtime = loadErrorMessage(realtimeResult.reason, tErrors);
  }

  let alertRules: Awaited<ReturnType<typeof fetchAlertRules>> = [];
  if (alertsResult.status === 'fulfilled') {
    alertRules = alertsResult.value;
  } else {
    loadErrors.alerts = loadErrorMessage(alertsResult.reason, tErrors);
  }

  const fatal =
    loadErrors.summary && loadErrors.list && !summary && list.rows.length === 0;

  if (fatal) {
    return (
      <AdminShell title={t('pageTitle')} activeItem="active-users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={loadErrors.summary ?? tErrors('somethingWentWrongTryAgain')} />
      </AdminShell>
    );
  }

  const engagementSection = (
    <Suspense fallback={<ActiveUsersEngagementFallback />}>
      <ActiveUsersEngagementSection />
    </Suspense>
  );

  const geoSection = (
    <Suspense fallback={<ActiveUsersGeoFallback />}>
      <ActiveUsersGeoSection />
    </Suspense>
  );

  return (
    <AdminShell title={t('pageTitle')} activeItem="active-users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ActiveUsersWorkspace
        initialSummary={summary}
        initialRows={list.rows}
        initialListTotal={list.total}
        initialRealtime={realtime}
        initialAlertRules={alertRules}
        initialFeedType={sp.feedType ?? ''}
        listFilters={{
          page,
          limit: ACTIVE_USERS_PAGE_SIZE,
          ...(sp.search ? { search: sp.search } : {}),
          ...(sp.status ? { status: sp.status } : {}),
          ...(sp.platform ? { platform: sp.platform } : {}),
        }}
        loadErrors={loadErrors}
        engagementSection={engagementSection}
        geoSection={geoSection}
      />
    </AdminShell>
  );
}

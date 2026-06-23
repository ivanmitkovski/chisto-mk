import { Suspense } from 'react';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import {
  DashboardKeyboardShortcuts,
  DashboardOfflineBanner,
  DashboardRealtimeSync,
  InsightsFallback,
  InsightsSection,
  ReportsFallback,
  ReportsSection,
  StatsFallback,
  StatsSection,
} from '@/features/dashboard-overview';
import { OperationsDegradedBanner } from '@/features/operations/components/operations-degraded-banner.server';
import { QuickActionsDropdown } from '@/features/dashboard-overview';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import styles from './dashboard.module.css';

export default async function DashboardPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['dashboard:view']);
  const t = await getTranslations('dashboard');
  const tCommon = await getTranslations('common');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  return (
    <AdminShell
      title={t('pageTitle')}
      activeItem="dashboard"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <div className={styles.page}>
        <DashboardOfflineBanner />
        <OperationsDegradedBanner />
        <DashboardKeyboardShortcuts />
        <a href="#reports-section" className="skipLink">
          {tCommon('skipToReports')}
        </a>
        <a href="#insights-section" className="skipLink">
          {tCommon('skipToInsights')}
        </a>
        <Suspense fallback={<StatsFallback />}>
          <header className={styles.topBar} role="banner">
            <div className={styles.statsWrap}>
              <StatsSection />
            </div>
            <QuickActionsDropdown />
          </header>
        </Suspense>
        <DashboardRealtimeSync />
        <main>
          <Suspense fallback={<ReportsFallback />}>
            <ReportsSection />
          </Suspense>
          <Suspense fallback={<InsightsFallback />}>
            <InsightsSection />
          </Suspense>
        </main>
      </div>
    </AdminShell>
  );
}

import { Suspense } from 'react';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import {
  DashboardContentFallback,
  DashboardDataOrError,
  DashboardKeyboardShortcuts,
  DashboardOfflineBanner,
  DashboardRealtimeSync,
  InsightsSection,
  QuickActionsDropdown,
  ReportsSection,
  StatsSection,
} from '@/features/dashboard-overview';
import styles from './dashboard.module.css';

export default async function DashboardPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell
      title="Overview"
      activeItem="dashboard"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <div className={styles.page}>
        <DashboardOfflineBanner />
        <DashboardKeyboardShortcuts />
        <a href="#reports-section" className="skipLink">
          Skip to reports
        </a>
        <a href="#insights-section" className="skipLink">
          Skip to insights
        </a>
        <Suspense fallback={<DashboardContentFallback />}>
          <DashboardDataOrError>
            <header className={styles.topBar} role="banner">
              <div className={styles.statsWrap}>
                <StatsSection />
              </div>
              <QuickActionsDropdown />
            </header>
            <DashboardRealtimeSync />
              <main>
                <ReportsSection />
                <InsightsSection />
              </main>
            </DashboardDataOrError>
          </Suspense>
      </div>
    </AdminShell>
  );
}

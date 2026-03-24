import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SkeletonCard, SkeletonTable } from '@/components/ui';
import styles from './loading.module.css';

export default async function DashboardLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Overview" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
      <div className={styles.page} aria-busy="true" aria-live="polite">
        <header className={styles.topBar}>
          <div className={styles.stats}>
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className={styles.statsSkeleton} />
            ))}
          </div>
          <div className={styles.actionsSkeleton} />
        </header>

        <section className={styles.reportsSection}>
          <div className={styles.reportsHeaderSkeleton} />
          <SkeletonTable rows={5} cols={4} />
        </section>

        <div className={styles.insightsRow}>
          <div className={styles.insightsHeadingSkeleton} />
          <SkeletonCard lines={3} />
          <SkeletonCard lines={4} />
          <SkeletonCard lines={2} />
        </div>
      </div>
    </AdminShell>
  );
}

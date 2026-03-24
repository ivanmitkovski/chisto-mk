import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './loading.module.css';
import pageStyles from './reports-page.module.css';

export default async function ReportsLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <div className={pageStyles.page}>
        <section className={styles.section} aria-busy="true">
          <span className={styles.sectionLabel}>Queue</span>
          <div className={styles.header}>
            <div className={styles.headerLeft}>
              <div className={styles.titleSkeleton} />
              <div className={styles.subtitleSkeleton} />
            </div>
          </div>
          <div className={styles.filterRow}>
            <div className={styles.filterChips}>
              {[1, 2, 3, 4, 5].map((i) => (
                <span key={i} className={styles.filterChipSkeleton} />
              ))}
            </div>
          </div>
          <div className={styles.card}>
            <div className={styles.tableSkeleton}>
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className={styles.rowSkeleton} />
              ))}
            </div>
          </div>
        </section>
      </div>
    </AdminShell>
  );
}

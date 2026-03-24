import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './report-detail-loading.module.css';

export default async function ReportDetailLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Report" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <div className={styles.page} aria-busy="true">
        <div className={styles.header}>
          <div className={styles.backSkeleton} />
          <div className={styles.titleSkeleton} />
        </div>
        <div className={styles.grid}>
          <div className={styles.mainSkeleton} />
          <div className={styles.railSkeleton} />
        </div>
      </div>
    </AdminShell>
  );
}

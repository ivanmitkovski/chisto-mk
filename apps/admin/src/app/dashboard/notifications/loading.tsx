import { cookies } from 'next/headers';
import { Card } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './loading.module.css';

export default async function NotificationsLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Notifications" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
      <div className={styles.root} aria-busy="true" aria-live="polite">
        <header className={styles.header}>
          <div>
            <span className={`${styles.line} ${styles.titleLine}`} />
            <span className={`${styles.line} ${styles.subtitleLine}`} />
          </div>
          <div className={styles.filters}>
            <span className={styles.chip} />
            <span className={styles.chip} />
            <span className={styles.chip} />
            <span className={styles.chip} />
          </div>
        </header>

        <Card className={styles.card}>
          <div className={styles.listHeader}>
            <span className={`${styles.line} ${styles.listTitle}`} />
            <span className={styles.button} />
          </div>

          <div className={styles.items}>
            <div className={styles.item}>
              <span className={styles.icon} />
              <div className={styles.text}>
                <span className={`${styles.line} ${styles.itemTitle}`} />
                <span className={`${styles.line} ${styles.itemBody}`} />
              </div>
              <span className={styles.dot} />
            </div>
            <div className={styles.item}>
              <span className={styles.icon} />
              <div className={styles.text}>
                <span className={`${styles.line} ${styles.itemTitle}`} />
                <span className={`${styles.line} ${styles.itemBody}`} />
              </div>
              <span className={styles.dot} />
            </div>
            <div className={styles.item}>
              <span className={styles.icon} />
              <div className={styles.text}>
                <span className={`${styles.line} ${styles.itemTitle}`} />
                <span className={`${styles.line} ${styles.itemBody}`} />
              </div>
              <span className={styles.dot} />
            </div>
          </div>
        </Card>
      </div>
    </AdminShell>
  );
}


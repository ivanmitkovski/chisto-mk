import { cookies } from 'next/headers';
import { Card } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './loading.module.css';

export default async function SettingsLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Settings" activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Card className={styles.card} aria-busy="true" aria-live="polite">
        <div className={styles.header}>
          <span className={`${styles.line} ${styles.lineLong}`} />
          <span className={`${styles.line} ${styles.lineShort}`} />
        </div>

        <div className={styles.section}>
          <div className={styles.panelBody} />
          <div className={styles.panelBody} />
        </div>
      </Card>
    </AdminShell>
  );
}

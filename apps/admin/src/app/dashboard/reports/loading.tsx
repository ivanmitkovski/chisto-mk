import { cookies } from 'next/headers';
import { Card } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './loading.module.css';

export default async function ReportsLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Card className={styles.card} aria-busy="true" aria-live="polite">
        <div className={styles.header}>
          <span className={`${styles.line} ${styles.lineLong}`} />
          <span className={`${styles.line} ${styles.lineShort}`} />
          <div className={styles.chips}>
            <span className={styles.chip} />
            <span className={styles.chip} />
          </div>
        </div>

        <div className={styles.grid}>
          <section className={styles.column}>
            <div className={styles.panel}>
              <div className={`${styles.panelBody} ${styles.panelBodyTall}`} />
            </div>
            <div className={styles.panel}>
              <div className={styles.panelBody} />
            </div>
            <div className={styles.panel}>
              <div className={styles.panelBody} />
            </div>
          </section>

          <aside className={styles.rail}>
            <div className={styles.panel}>
              <div className={styles.panelBody}>
                <div className={styles.column}>
                  <span className={styles.actionBar} />
                  <span className={styles.actionBar} />
                  <span className={styles.actionBar} />
                </div>
              </div>
            </div>
            <div className={styles.panel}>
              <div className={styles.panelBody} />
            </div>
          </aside>
        </div>
      </Card>
    </AdminShell>
  );
}

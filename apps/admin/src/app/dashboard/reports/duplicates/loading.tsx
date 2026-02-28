'use client';

import { useEffect, useState } from 'react';
import { Card } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import {
  DESKTOP_SIDEBAR_COOKIE_KEY,
  DESKTOP_SIDEBAR_STORAGE_KEY,
} from '@/features/admin-shell/constants';
import styles from './loading.module.css';

function readSidebarPreference(): boolean {
  if (typeof window === 'undefined') {
    return false;
  }

  const persisted = window.localStorage.getItem(DESKTOP_SIDEBAR_STORAGE_KEY);
  if (persisted === '1' || persisted === '0') {
    return persisted === '1';
  }

  const cookieEntry = document.cookie
    .split(';')
    .map((chunk) => chunk.trim())
    .find((chunk) => chunk.startsWith(`${DESKTOP_SIDEBAR_COOKIE_KEY}=`));

  return cookieEntry?.split('=')[1] === '1';
}

export default function DuplicateReportsLoading() {
  const [initialSidebarCollapsed, setInitialSidebarCollapsed] = useState<boolean>(() =>
    readSidebarPreference(),
  );

  useEffect(() => {
    setInitialSidebarCollapsed(readSidebarPreference());
  }, []);

  return (
    <AdminShell
      title="Duplicate Reports"
      activeItem="duplicates"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <div className={styles.layout} aria-busy="true" aria-live="polite">
        <Card className={styles.groupsPanel}>
          <div className={styles.panelHeader}>
            <span className={`${styles.line} ${styles.lineLong}`} />
            <span className={`${styles.line} ${styles.lineShort}`} />
          </div>

          <div className={styles.groupList}>
            <span className={styles.groupItem} />
            <span className={styles.groupItem} />
            <span className={styles.groupItem} />
            <span className={styles.groupItem} />
          </div>
        </Card>

        <Card className={styles.detailPanel}>
          <div className={styles.panelHeader}>
            <span className={`${styles.line} ${styles.lineLong}`} />
            <span className={`${styles.line} ${styles.lineShort}`} />
          </div>

          <span className={styles.blockTall} />

          <div className={styles.list}>
            <span className={styles.row} />
            <span className={styles.row} />
            <span className={styles.row} />
          </div>

          <div className={styles.footer}>
            <span className={styles.button} />
          </div>
        </Card>
      </div>
    </AdminShell>
  );
}

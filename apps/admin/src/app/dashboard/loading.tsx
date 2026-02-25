'use client';

import { useEffect, useState } from 'react';
import { DESKTOP_SIDEBAR_STORAGE_KEY } from '@/features/admin-shell/constants';
import styles from '../shared/route-state.module.css';

export default function DashboardLoading() {
  const [isMobile, setIsMobile] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(max-width: 48rem)');

    const applyState = (matches: boolean) => {
      setIsMobile(matches);
    };

    applyState(mediaQuery.matches);

    const onChange = (event: MediaQueryListEvent) => applyState(event.matches);
    mediaQuery.addEventListener('change', onChange);

    return () => mediaQuery.removeEventListener('change', onChange);
  }, []);

  useEffect(() => {
    const persistedValue = window.localStorage.getItem(DESKTOP_SIDEBAR_STORAGE_KEY);
    setIsSidebarCollapsed(persistedValue === '1');
  }, []);

  const dashboardShellClassName = [
    styles.dashboardShell,
    isSidebarCollapsed && !isMobile ? styles.dashboardShellCollapsed : '',
    isMobile ? styles.dashboardShellMobile : '',
  ]
    .join(' ')
    .trim();

  const sideNavClassName = [styles.sideNav, isSidebarCollapsed && !isMobile ? styles.sideNavCollapsed : '']
    .join(' ')
    .trim();

  return (
    <main className={styles.wrapper}>
      <section className={dashboardShellClassName} aria-busy="true" aria-live="polite">
        <aside className={sideNavClassName}>
          <span className={styles.navItem} />
          <span className={styles.navItem} />
          <span className={styles.navItem} />
        </aside>
        <div className={styles.mainShell}>
          <div className={styles.topBar}>
            <span className={styles.topTitle} />
            <div className={styles.topActions}>
              <span className={styles.searchBar} />
              <span className={styles.actionPill} />
              <span className={styles.actionPill} />
            </div>
          </div>
          <div className={styles.content}>
            <div className={styles.stats}>
              <span className={styles.statsCard} />
              <span className={styles.statsCard} />
              <span className={styles.statsCard} />
              <span className={styles.statsCard} />
            </div>
            <span className={styles.tableCard} />
            <div className={styles.tableRows}>
              <span className={styles.tableRow} />
              <span className={styles.tableRow} />
              <span className={styles.tableRow} />
              <span className={styles.tableRow} />
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}

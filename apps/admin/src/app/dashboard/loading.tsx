import styles from '../shared/route-state.module.css';

export default function DashboardLoading() {
  return (
    <main className={styles.wrapper}>
      <section className={styles.dashboardShell} aria-busy="true" aria-live="polite">
        <aside className={styles.sideNav}>
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

import styles from '../skeleton.module.css';

export function NotificationsSkeleton() {
  return (
    <>
      <header className={styles.notificationsHeader} aria-hidden>
        <div className={styles.notificationsHeaderText}>
          <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.reportsTitleBar}`} />
          <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.reportsSubtitleBar}`} />
        </div>
        <div className={styles.filterChipsRow}>
          {Array.from({ length: 5 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.filterChip}`} />
          ))}
        </div>
      </header>
      <div className={`${styles.card} ${styles.notificationsListCard}`} aria-busy="true">
        <div className={styles.notificationList} aria-hidden>
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className={styles.notificationRow}>
              <span className={`${styles.shimmerBlock} ${styles.listRowIcon}`} />
              <div className={styles.notificationRowText}>
                <span className={`${styles.shimmerBlock} ${styles.listRowLine}`} />
                <span className={`${styles.shimmerBlock} ${styles.listRowLine} ${styles.listRowLineShort}`} />
              </div>
              <span className={`${styles.shimmerBlock} ${styles.listRowDot}`} />
            </div>
          ))}
        </div>
      </div>
    </>
  );
}

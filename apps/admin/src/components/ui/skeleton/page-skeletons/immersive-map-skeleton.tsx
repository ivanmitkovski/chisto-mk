import styles from '../skeleton.module.css';

export function ImmersiveMapSkeleton() {
  return <span className={`${styles.shimmerBlock} ${styles.mapBlock}`} aria-hidden />;
}

import styles from './skeleton.module.css';

type SkeletonCardProps = {
  lines?: number;
};

export function SkeletonCard({ lines = 3 }: SkeletonCardProps) {
  return (
    <div className={styles.card}>
      {Array.from({ length: lines }).map((_, i) => (
        <span key={i} className={`${styles.bar} ${i === 0 ? styles.title : ''}`} />
      ))}
    </div>
  );
}

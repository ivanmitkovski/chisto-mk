import { SkeletonCard } from '../skeleton-card';
import { SkeletonListItem } from '../skeleton-list-item';
import styles from '../skeleton.module.css';

type PanelSkeletonProps = {
  variant?: 'card' | 'list';
  lines?: number;
  listItems?: number;
};

/** Compact in-section loading placeholder (tabs, timelines, insights). */
export function PanelSkeleton({ variant = 'card', lines = 3, listItems = 4 }: PanelSkeletonProps) {
  if (variant === 'list') {
    return (
      <div className={styles.listVariant}>
        {Array.from({ length: listItems }).map((_, i) => (
          <SkeletonListItem key={i} lines={2} />
        ))}
      </div>
    );
  }
  return <SkeletonCard lines={lines} />;
}

import { SkeletonCard } from '@/components/ui';
import styles from '@/app/shared/route-state.module.css';

export default function AcceptInviteLoading() {
  return (
    <div className={styles.loginShell} aria-busy="true" role="status">
      <div className={styles.loginPanel}>
        <SkeletonCard lines={4} />
      </div>
    </div>
  );
}

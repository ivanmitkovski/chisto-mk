'use client';

import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import styles from './event-detail.module.css';

type EventDetailModerationBarProps = {
  isPending: boolean;
  canWriteCleanupEvents: boolean;
  saving: boolean;
  onApprove: () => void;
  onDecline: () => void;
  moderationHint: string;
};

export function EventDetailModerationBar({
  isPending,
  canWriteCleanupEvents,
  saving,
  onApprove,
  onDecline,
  moderationHint,
}: EventDetailModerationBarProps) {
  const tDetail = useTranslations('events.detail');

  return (
    <>
      {isPending && canWriteCleanupEvents ? (
        <div className={styles.approveDeclineBar}>
          <p className={styles.approveDeclineHint}>{tDetail('moderationPendingHint')}</p>
          <div className={styles.approveDeclineActions}>
            <Button onClick={onApprove} isLoading={saving}>
              <Icon name="check" size={14} />
              {tDetail('approve')}
            </Button>
            <Button variant="outline" onClick={onDecline} disabled={saving} className={styles.declineBtn}>
              {tDetail('decline')}
            </Button>
          </div>
        </div>
      ) : null}
      {isPending && !canWriteCleanupEvents ? (
        <p className={styles.approveDeclineHint} role="note">
          {tDetail('moderationPendingReadOnly')}
        </p>
      ) : null}
      <p className={styles.moderationHint}>{moderationHint}</p>
    </>
  );
}

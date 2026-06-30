'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import styles from './events-workspace.module.css';

type EventsBulkBarProps = {
  selectedCount: number;
  bulkBusy: boolean;
  onSelectPage: () => void;
  onClear: () => void;
  onApprove: () => void;
  onDecline: () => void;
};

export function EventsBulkBar({
  selectedCount,
  bulkBusy,
  onSelectPage,
  onClear,
  onApprove,
  onDecline,
}: EventsBulkBarProps) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.moderationBulkBar}>
      <span className={styles.moderationBulkMeta}>
        {t('bulk.selectedMeta', { count: selectedCount })}
      </span>
      <div className={styles.moderationBulkActions}>
        <Button variant="outline" size="sm" type="button" onClick={onSelectPage} disabled={bulkBusy}>
          {t('bulk.selectPage')}
        </Button>
        <Button variant="outline" size="sm" type="button" onClick={onClear} disabled={bulkBusy}>
          {tCommon('clear')}
        </Button>
        <Button
          variant="solid"
          size="sm"
          type="button"
          onClick={() => void onApprove()}
          isLoading={bulkBusy}
          disabled={selectedCount === 0}
        >
          {t('bulk.approveSelected')}
        </Button>
        <Button
          variant="outline"
          size="sm"
          type="button"
          onClick={onDecline}
          disabled={bulkBusy || selectedCount === 0}
        >
          {t('bulk.declineSelected')}
        </Button>
      </div>
    </div>
  );
}

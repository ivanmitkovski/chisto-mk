'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import styles from './bulk-action-bar.module.css';

type BulkActionBarProps = {
  selectedCount: number;
  totalCount?: number;
  actions: Array<{ id: string; label: string; tone?: 'neutral' | 'danger'; disabled?: boolean; onClick: () => void }>;
  onClear: () => void;
};

export function BulkActionBar({ selectedCount, totalCount, actions, onClear }: BulkActionBarProps) {
  const tUi = useTranslations('ui');
  const tCommon = useTranslations('common');

  if (selectedCount <= 0) return null;

  const selectionLabel =
    totalCount != null
      ? tUi('selectedCountOfTotal', { count: selectedCount, total: totalCount })
      : tUi('selectedCount', { count: selectedCount });

  return (
    <div className={styles.bar} role="region" aria-label={tCommon('bulkActions')}>
      <span>{selectionLabel}</span>
      <div className={styles.actions}>
        {actions.map((action) => (
          <Button
            key={action.id}
            type="button"
            variant={action.tone === 'danger' ? 'solid' : 'outline'}
            disabled={action.disabled}
            onClick={action.onClick}
          >
            {action.label}
          </Button>
        ))}
        <Button type="button" variant="outline" onClick={onClear}>
          {tCommon('clear')}
        </Button>
      </div>
    </div>
  );
}

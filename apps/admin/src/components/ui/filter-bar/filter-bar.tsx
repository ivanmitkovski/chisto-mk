'use client';

import type { ReactNode } from 'react';
import { useTranslations } from 'next-intl';

import { Button } from '../button';
import { Card } from '../card';
import styles from './filter-bar.module.css';

export type FilterBarProps = {
  children: ReactNode;
  label?: string;
  onApply: () => void;
  onClear?: () => void;
  applyLabel?: string;
  clearLabel?: string;
  applyDisabled?: boolean;
  clearDisabled?: boolean;
  className?: string;
};

export function FilterBar({
  children,
  label,
  onApply,
  onClear,
  applyLabel,
  clearLabel,
  applyDisabled = false,
  clearDisabled = false,
  className,
}: FilterBarProps) {
  const tUi = useTranslations('ui');
  const tCommon = useTranslations('common');
  const resolvedLabel = label ?? tUi('filters');
  const resolvedApplyLabel = applyLabel ?? tUi('applyFilters');
  const resolvedClearLabel = clearLabel ?? tCommon('clear');
  const rootClassName = [styles.root, className ?? ''].join(' ').trim();

  return (
    <Card padding="md" className={rootClassName}>
      {resolvedLabel ? <span className={styles.label}>{resolvedLabel}</span> : null}
      <div className={styles.grid}>{children}</div>
      <div className={styles.actions}>
        <Button type="button" onClick={onApply} disabled={applyDisabled}>
          {resolvedApplyLabel}
        </Button>
        {onClear ? (
          <Button type="button" variant="outline" onClick={onClear} disabled={clearDisabled}>
            {resolvedClearLabel}
          </Button>
        ) : null}
      </div>
    </Card>
  );
}

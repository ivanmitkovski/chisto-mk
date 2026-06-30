'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Input, Modal, Select } from '@/components/ui';
import { ADMIN_ALERT_METRICS } from '../constants/active-users-filters';
import type { AdminAlertRule } from '../data/active-users.types';
import styles from './alert-rule-form-modal.module.css';

export type AlertRuleFormValues = {
  metric: string;
  threshold: number;
  windowSeconds: number;
  comparator: 'GT' | 'GTE';
  enabled: boolean;
};

type AlertRuleFormModalProps = {
  open: boolean;
  busy?: boolean;
  initial?: AdminAlertRule | null;
  onClose: () => void;
  onSubmit: (values: AlertRuleFormValues) => void;
};

export function AlertRuleFormModal({
  open,
  busy = false,
  initial = null,
  onClose,
  onSubmit,
}: AlertRuleFormModalProps) {
  const t = useTranslations('activeUsers');
  const tCommon = useTranslations('common');
  const [metric, setMetric] = useState(initial?.metric ?? ADMIN_ALERT_METRICS[0]);
  const [threshold, setThreshold] = useState(String(initial?.threshold ?? 100));
  const [windowSeconds, setWindowSeconds] = useState(String(initial?.windowSeconds ?? 300));
  const [comparator, setComparator] = useState<'GT' | 'GTE'>(
    (initial?.comparator as 'GT' | 'GTE') ?? 'GT',
  );
  const [enabled, setEnabled] = useState(initial?.enabled ?? true);

  const isEdit = Boolean(initial);

  return (
    <Modal
      open={open}
      title={isEdit ? t('alerts.editTitle') : t('alerts.createTitle')}
      description={t('alerts.formDescription')}
      onClose={() => !busy && onClose()}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button
            type="button"
            disabled={busy || !metric || !threshold.trim()}
            onClick={() =>
              onSubmit({
                metric,
                threshold: Number(threshold),
                windowSeconds: Number(windowSeconds) || 300,
                comparator,
                enabled,
              })
            }
          >
            {busy ? tCommon('saving') : isEdit ? tCommon('saveChanges') : t('alerts.create')}
          </Button>
        </div>
      }
    >
      <div className={styles.form}>
        <Select
          label={t('alerts.metricLabel')}
          value={metric}
          onChange={(e) => setMetric(e.target.value)}
          disabled={busy || isEdit}
          options={ADMIN_ALERT_METRICS.map((m) => ({
            value: m,
            label: t(`alerts.metrics.${m}`),
          }))}
        />
        <Select
          label={t('alerts.comparatorLabel')}
          value={comparator}
          onChange={(e) => setComparator(e.target.value as 'GT' | 'GTE')}
          disabled={busy}
          options={[
            { value: 'GT', label: t('alerts.comparators.gt') },
            { value: 'GTE', label: t('alerts.comparators.gte') },
          ]}
        />
        <Input
          label={t('alerts.thresholdLabel')}
          type="number"
          value={threshold}
          onChange={(e) => setThreshold(e.target.value)}
          disabled={busy}
        />
        <Input
          label={t('alerts.windowLabel')}
          type="number"
          value={windowSeconds}
          onChange={(e) => setWindowSeconds(e.target.value)}
          disabled={busy}
        />
        <label className={styles.checkbox}>
          <input
            type="checkbox"
            checked={enabled}
            onChange={(e) => setEnabled(e.target.checked)}
            disabled={busy}
          />
          {t('alerts.enabledLabel')}
        </label>
      </div>
    </Modal>
  );
}

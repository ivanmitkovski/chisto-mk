'use client';

import { useState } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { Button, Card, ConfirmDialog, SectionState, useToast } from '@/components/ui';
import { formatAdminDateTime } from '@/lib/i18n/format-admin-datetime';
import type { AdminAlertRule } from '../data/active-users.types';
import {
  browserCreateAlertRule,
  browserDeleteAlertRule,
  browserUpdateAlertRule,
} from '../data/active-users-adapter.client';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import { AlertRuleFormModal, type AlertRuleFormValues } from './alert-rule-form-modal';
import styles from './alerts-panel.module.css';

type AlertsPanelProps = {
  loadError?: string | undefined;
};

export function AlertsPanel({ loadError }: AlertsPanelProps) {
  const t = useTranslations('activeUsers');
  const tCommon = useTranslations('common');
  const locale = useLocale();
  const { showToast } = useToast();
  const { alertRules, setAlertRules, highlightedAlertId } = useActiveUsersLive();
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<AdminAlertRule | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<AdminAlertRule | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleCreate(values: AlertRuleFormValues) {
    setBusy(true);
    try {
      const created = await browserCreateAlertRule({
        metric: values.metric,
        threshold: values.threshold,
        windowSeconds: values.windowSeconds,
        comparator: values.comparator,
      });
      if (!values.enabled) {
        await browserUpdateAlertRule(created.id, { enabled: false });
      }
      setAlertRules([{ ...created, enabled: values.enabled }, ...alertRules]);
      setFormOpen(false);
      showToast({ tone: 'success', title: t('alerts.createdTitle'), message: t('alerts.createdMessage') });
    } catch {
      showToast({ tone: 'warning', title: tCommon('error'), message: t('alerts.saveFailed') });
    } finally {
      setBusy(false);
    }
  }

  async function handleEdit(values: AlertRuleFormValues) {
    if (!editing) return;
    setBusy(true);
    try {
      const updated = await browserUpdateAlertRule(editing.id, {
        threshold: values.threshold,
        enabled: values.enabled,
      });
      setAlertRules(alertRules.map((r) => (r.id === editing.id ? { ...r, ...updated } : r)));
      setEditing(null);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('alerts.updatedMessage') });
    } catch {
      showToast({ tone: 'warning', title: tCommon('error'), message: t('alerts.saveFailed') });
    } finally {
      setBusy(false);
    }
  }

  async function handleToggle(rule: AdminAlertRule) {
    try {
      const updated = await browserUpdateAlertRule(rule.id, { enabled: !rule.enabled });
      setAlertRules(alertRules.map((r) => (r.id === rule.id ? { ...r, ...updated } : r)));
    } catch {
      showToast({ tone: 'warning', title: tCommon('error'), message: t('alerts.saveFailed') });
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setBusy(true);
    try {
      await browserDeleteAlertRule(deleteTarget.id);
      setAlertRules(alertRules.filter((r) => r.id !== deleteTarget.id));
      setDeleteTarget(null);
      showToast({ tone: 'success', title: t('alerts.deletedTitle'), message: t('alerts.deletedMessage') });
    } catch {
      showToast({ tone: 'warning', title: tCommon('error'), message: t('alerts.deleteFailed') });
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card padding="md" className={styles.panel}>
      <div className={styles.header}>
        <h3 className={styles.title}>{t('alertsTitle')}</h3>
        <Button type="button" variant="outline" size="sm" onClick={() => setFormOpen(true)}>
          {t('alerts.add')}
        </Button>
      </div>

      {loadError ? (
        <SectionState variant="error" message={loadError} />
      ) : alertRules.length === 0 ? (
        <p className={styles.empty}>{t('noAlerts')}</p>
      ) : (
        <ul className={styles.list}>
          {alertRules.map((rule) => (
            <li
              key={rule.id}
              className={`${styles.item} ${highlightedAlertId === rule.id ? styles.highlighted : ''}`}
            >
              <div className={styles.itemMain}>
                <strong>{t(`alerts.metrics.${rule.metric}` as 'alerts.metrics.CONCURRENT')}</strong>
                <span>
                  {t(
                    `alerts.comparators.${rule.comparator.toLowerCase()}` as 'alerts.comparators.gt',
                  )}{' '}
                  {rule.threshold}
                </span>
                <span className={rule.enabled ? styles.enabled : styles.disabled}>
                  {rule.enabled ? t('enabled') : t('disabled')}
                </span>
                {rule.lastTriggeredAt ? (
                  <span className={styles.meta}>
                    {t('alerts.lastTriggered', {
                      value: formatAdminDateTime(rule.lastTriggeredAt, locale),
                    })}
                  </span>
                ) : null}
              </div>
              <div className={styles.actions}>
                <Button type="button" variant="ghost" size="sm" onClick={() => handleToggle(rule)}>
                  {rule.enabled ? t('alerts.disable') : t('alerts.enable')}
                </Button>
                <Button type="button" variant="ghost" size="sm" onClick={() => setEditing(rule)}>
                  {tCommon('edit')}
                </Button>
                <Button type="button" variant="ghost" size="sm" onClick={() => setDeleteTarget(rule)}>
                  {tCommon('delete')}
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}

      <AlertRuleFormModal open={formOpen} busy={busy} onClose={() => setFormOpen(false)} onSubmit={handleCreate} />
      <AlertRuleFormModal
        open={editing != null}
        busy={busy}
        initial={editing}
        onClose={() => setEditing(null)}
        onSubmit={handleEdit}
      />
      <ConfirmDialog
        open={deleteTarget != null}
        title={t('alerts.deleteTitle')}
        description={t('alerts.deleteDescription')}
        confirmLabel={tCommon('delete')}
        tone="danger"
        isLoading={busy}
        onConfirm={() => void confirmDelete()}
        onClose={() => setDeleteTarget(null)}
      />
    </Card>
  );
}

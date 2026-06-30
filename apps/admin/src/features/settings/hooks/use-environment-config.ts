'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { ApiError } from '@/lib/api';
import type { ConfigEntry } from '@/features/settings/data/config-adapter';

function cloneEntries(entries: ConfigEntry[]): ConfigEntry[] {
  return entries.map((entry) => ({ ...entry }));
}

export function useEnvironmentConfig(initialConfig: ConfigEntry[]) {
  const t = useTranslations('settings.environment');
  const tCommon = useTranslations('common');
  const [baseline, setBaseline] = useState<ConfigEntry[]>(() => cloneEntries(initialConfig));
  const [rows, setRows] = useState<ConfigEntry[]>(() => cloneEntries(initialConfig));
  const [busy, setBusy] = useState(false);
  const { showToast, clearToast } = useToast();

  useEffect(() => {
    const next = cloneEntries(initialConfig);
    setBaseline(next);
    setRows(next);
  }, [initialConfig]);

  async function saveConfig() {
    setBusy(true);
    clearToast();
    const snapshot = cloneEntries(rows);
    try {
      await adminBrowserFetch('/admin/config/validate', {
        method: 'POST',
        body: { entries: rows.map((r) => ({ key: r.key, value: r.value })) },
      });
      await adminBrowserFetch('/admin/config', {
        method: 'PATCH',
        body: { entries: rows.map((r) => ({ key: r.key, value: r.value })) },
      });
      setBaseline(snapshot);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('savedToast') });
    } catch (err) {
      setRows(cloneEntries(baseline));
      const msg = err instanceof ApiError ? err.message : tCommon('saveFailed');
      showToast({ tone: 'warning', title: tCommon('errorGeneric'), message: msg });
    } finally {
      setBusy(false);
    }
  }

  function updateRowValue(index: number, value: string) {
    setRows((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], value };
      return next;
    });
  }

  const isDirty = JSON.stringify(rows) !== JSON.stringify(baseline);

  return { rows, busy, isDirty, saveConfig, updateRowValue };
}

'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import type { FeatureFlagRow } from '@/features/settings/data/feature-flags-adapter';

export function useFeatureFlags(initialFlags: FeatureFlagRow[]) {
  const t = useTranslations('settings.featureFlags');
  const tCommon = useTranslations('common');
  const [flags, setFlags] = useState<FeatureFlagRow[]>(() => initialFlags.map((f) => ({ ...f })));
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [pendingToggle, setPendingToggle] = useState<{ key: string; enabled: boolean } | null>(null);
  const { showToast } = useToast();

  async function applyToggle(key: string, enabled: boolean) {
    const previous = flags.find((f) => f.key === key)?.enabled;
    setBusyKey(key);
    setFlags((prev) => prev.map((f) => (f.key === key ? { ...f, enabled } : f)));
    try {
      const res = await adminBrowserFetch<{ key: string; enabled: boolean }>(
        `/admin/feature-flags/${encodeURIComponent(key)}`,
        { method: 'PATCH', body: { enabled } },
      );
      setFlags((prev) => prev.map((f) => (f.key === key ? { ...f, enabled: res.enabled } : f)));
    } catch {
      if (previous != null) {
        setFlags((prev) => prev.map((f) => (f.key === key ? { ...f, enabled: previous } : f)));
      }
      showToast({ tone: 'warning', title: tCommon('errorGeneric'), message: t('updateError') });
    } finally {
      setBusyKey(null);
      setPendingToggle(null);
    }
  }

  function toggleFlag(key: string, enabled: boolean) {
    setPendingToggle({ key, enabled });
  }

  return { flags, busyKey, pendingToggle, setPendingToggle, toggleFlag, applyToggle };
}

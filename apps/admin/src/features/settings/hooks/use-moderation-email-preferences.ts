'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import type {
  ModerationEmailCategory,
  ModerationEmailPreferenceRow,
} from '@/features/settings/data/moderation-email-preferences.types';

export function useModerationEmailPreferences(initial: ModerationEmailPreferenceRow[]) {
  const t = useTranslations('settings.moderationEmails');
  const tCommon = useTranslations('common');
  const { showToast } = useToast();
  const [rows, setRows] = useState(initial);
  const [busyCategory, setBusyCategory] = useState<ModerationEmailCategory | null>(null);

  const toggle = useCallback(async (category: ModerationEmailCategory, enabled: boolean) => {
    const previous = rows.find((row) => row.category === category);
    setBusyCategory(category);
    setRows((prev) =>
      prev.map((r) => (r.category === category ? { ...r, enabled, source: 'explicit' as const } : r)),
    );
    try {
      const next = await adminBrowserFetch<ModerationEmailPreferenceRow[]>(
        '/admin/me/moderation-email-preferences',
        { method: 'PATCH', body: { category, enabled } },
      );
      setRows(next);
    } catch {
      if (previous) {
        setRows((prev) =>
          prev.map((r) => (r.category === category ? previous : r)),
        );
      }
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: t('updateFailed'),
      });
    } finally {
      setBusyCategory(null);
    }
  }, [rows, showToast, t, tCommon]);

  return { rows, busyCategory, toggle };
}

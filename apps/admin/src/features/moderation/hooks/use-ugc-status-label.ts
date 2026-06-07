'use client';

import { useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { formatUgcLabel } from '../lib/ugc-moderation-utils';

const UGC_STATUS_MESSAGE_KEYS: Record<string, string> = {
  OPEN: 'statusOptions.open',
  ESCALATED: 'statusOptions.escalated',
  REVIEWED: 'statusOptions.reviewed',
  DISMISSED: 'statusOptions.dismissed',
  HIDDEN: 'statusOptions.hidden',
};

export function useUgcStatusLabel() {
  const t = useTranslations('moderation');

  return useCallback(
    (status: string) => {
      const key = UGC_STATUS_MESSAGE_KEYS[status];
      return key ? t(key) : formatUgcLabel(status);
    },
    [t],
  );
}

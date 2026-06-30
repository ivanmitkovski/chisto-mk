'use client';

import { useCallback } from 'react';
import { useTranslations } from 'next-intl';
import type { ReportStatus } from '../types';

export function useFormatReportStatus() {
  const t = useTranslations('reports');

  return useCallback(
    (status: ReportStatus) => t(`status.${status}`),
    [t],
  );
}

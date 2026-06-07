'use client';

import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import type { ReportViewerPresenceEntry } from '@/lib/realtime';
import styles from './report-detail-page.module.css';

type ReportViewersBannerProps = {
  viewers: ReportViewerPresenceEntry[];
};

function uniqueByUserId(viewers: ReportViewerPresenceEntry[]): ReportViewerPresenceEntry[] {
  const seen = new Set<string>();
  const unique: ReportViewerPresenceEntry[] = [];
  for (const viewer of viewers) {
    if (seen.has(viewer.userId)) continue;
    seen.add(viewer.userId);
    unique.push(viewer);
  }
  return unique;
}

export function ReportViewersBanner({ viewers }: ReportViewersBannerProps) {
  const t = useTranslations('reports.viewers');
  const uniqueViewers = uniqueByUserId(viewers);

  if (uniqueViewers.length === 0) {
    return null;
  }

  let message: string;
  if (uniqueViewers.length === 1) {
    message = t('oneOther', { name: uniqueViewers[0]!.displayName });
  } else if (uniqueViewers.length === 2) {
    message = t('twoOthers', {
      firstName: uniqueViewers[0]!.displayName,
      secondName: uniqueViewers[1]!.displayName,
    });
  } else {
    message = t('manyOthers', {
      firstName: uniqueViewers[0]!.displayName,
      count: uniqueViewers.length - 1,
    });
  }

  return (
    <div className={styles.viewersNotice} role="status">
      <span className={styles.viewersLiveDot} aria-hidden />
      <Icon name="users" size={16} aria-hidden />
      <span>{message}</span>
    </div>
  );
}

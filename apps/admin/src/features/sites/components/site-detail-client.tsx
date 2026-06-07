'use client';

import { useState } from 'react';
import { SiteTimelineNoteForm } from '@/features/sites/components/site-timeline-note-form';
import { SiteTimelinePanel } from '@/features/sites/components/site-timeline-panel';
import { SiteStatusForm } from './site-status-form';
import styles from './site-detail.module.css';

type SiteDetailClientProps = {
  siteId: string;
  initialStatus: string;
  initialArchivedByAdmin: boolean;
  initialArchiveReason: string | null;
  latitude: number;
  longitude: number;
  description: string | null;
  reportCount: number;
  createdAt: string;
};

export function SiteDetailClient(props: SiteDetailClientProps) {
  const [timelineRefresh, setTimelineRefresh] = useState(0);

  return (
    <div className={styles.twoColumn}>
      <div className={styles.columnMain}>
        <SiteStatusForm {...props} />
      </div>
      <div className={styles.columnSide}>
        <SiteTimelinePanel siteId={props.siteId} refreshToken={timelineRefresh} />
        <SiteTimelineNoteForm
          siteId={props.siteId}
          onPosted={() => setTimelineRefresh((n) => n + 1)}
        />
      </div>
    </div>
  );
}

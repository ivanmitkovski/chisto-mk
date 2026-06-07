'use client';

import { useTranslations } from 'next-intl';
import { Badge, Icon, PageHeader } from '@/components/ui';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { formatEventAdminDateTime } from '@/features/events/lib/event-admin-datetime';
import { useAdminBcp47Locale } from '@/lib/i18n';
import styles from './event-detail.module.css';

type EventDetailHeaderProps = {
  event: CleanupEventDetail;
  declineReason?: string | null;
};

function moderationTone(status: string): 'warning' | 'success' | 'danger' | 'neutral' {
  if (status === 'PENDING') return 'warning';
  if (status === 'DECLINED') return 'danger';
  if (status === 'APPROVED') return 'success';
  return 'neutral';
}

export function EventDetailHeader({ event, declineReason = null }: EventDetailHeaderProps) {
  const tDetail = useTranslations('events.detail');
  const tTable = useTranslations('events.table');
  const locale = useAdminBcp47Locale();
  const isCompleted = !!event.completedAt;

  return (
    <div className={styles.headerBlock}>
      <PageHeader
        kicker={tDetail('moderationWorkspace')}
        title={event.title}
        {...(event.description ? { description: event.description } : {})}
      />
      <div className={styles.headerPills}>
        <Badge tone={isCompleted ? 'success' : 'info'}>
          {isCompleted ? tTable('completed') : tTable('upcoming')}
        </Badge>
        <Badge tone="neutral">{event.lifecycleStatus}</Badge>
        <Badge tone={moderationTone(event.status ?? 'APPROVED')}>{event.status ?? 'APPROVED'}</Badge>
      </div>
      {event.status === 'DECLINED' && declineReason ? (
        <div className={styles.declineReasonBox} role="note">
          <span className={styles.metaLabel}>{tDetail('declineReasonLabel')}</span>
          <span>{declineReason}</span>
        </div>
      ) : null}
      {event.moderatedBy && event.moderatedAt ? (
        <p className={styles.fieldHint}>
          {tDetail('moderatedByMeta', {
            email: event.moderatedBy.email,
            when: formatEventAdminDateTime(event.moderatedAt, locale),
          })}
        </p>
      ) : null}
      <div className={styles.metaRow}>
        <div className={styles.metaItem}>
          <span className={styles.metaLabel}>{tTable('scheduled')}</span>
          <span className={styles.metaValue}>
            <Icon name="calendar" size={14} aria-hidden />
            {formatEventAdminDateTime(event.scheduledAt, locale)}
          </span>
        </div>
        {event.endAt ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('endTime')}</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.endAt, locale)}</span>
          </div>
        ) : null}
        {event.completedAt ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tTable('completed')}</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.completedAt, locale)}</span>
          </div>
        ) : null}
        <div className={styles.metaItem}>
          <span className={styles.metaLabel}>{tTable('participants')}</span>
          <span className={styles.metaValue}>{event.participantCount}</span>
        </div>
      </div>
    </div>
  );
}

'use client';

import { useTranslations } from 'next-intl';
import { Badge } from '@/components/ui';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { formatEventAdminDateTime } from '@/features/events/lib/event-admin-datetime';
import { useAdminBcp47Locale } from '@/lib/i18n';
import styles from './event-detail.module.css';

type EventDetailMetaPanelProps = {
  event: CleanupEventDetail;
};

export function EventDetailMetaPanel({ event }: EventDetailMetaPanelProps) {
  const tDetail = useTranslations('events.detail');
  const locale = useAdminBcp47Locale();

  return (
    <section className={styles.sectionCard} aria-label={tDetail('metaPanelAria')}>
      <span className={styles.sectionLabel}>{tDetail('eventDetails')}</span>
      <div className={styles.metaGrid}>
        {event.createdAt ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('createdAt')}</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.createdAt, locale)}</span>
          </div>
        ) : null}
        {event.updatedAt ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('updatedAt')}</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.updatedAt, locale)}</span>
          </div>
        ) : null}
        {event.category ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('category')}</span>
            <span className={styles.metaValue}>{tDetail(`categoryValues.${event.category}`)}</span>
          </div>
        ) : null}
        {event.scale ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('scale')}</span>
            <span className={styles.metaValue}>{tDetail(`scaleValues.${event.scale}`)}</span>
          </div>
        ) : null}
        {event.difficulty ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('difficulty')}</span>
            <span className={styles.metaValue}>{tDetail(`difficultyValues.${event.difficulty}`)}</span>
          </div>
        ) : null}
        {event.maxParticipants != null ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tDetail('maxParticipants')}</span>
            <span className={styles.metaValue}>{event.maxParticipants}</span>
          </div>
        ) : null}
        <div className={styles.metaItem}>
          <span className={styles.metaLabel}>{tDetail('checkInStatus')}</span>
          <span className={styles.metaValue}>
            <Badge tone={event.checkInOpen ? 'success' : 'neutral'}>
              {event.checkInOpen ? tDetail('checkInOpen') : tDetail('checkInClosed')}
            </Badge>
            {' · '}
            {tDetail('checkedInCount', { count: event.checkedInCount ?? 0 })}
          </span>
        </div>
      </div>
      {event.gear && event.gear.length > 0 ? (
        <div className={styles.gearRow}>
          <span className={styles.metaLabel}>{tDetail('gear')}</span>
          <div className={styles.gearChips}>
            {event.gear.map((item) => (
              <Badge key={item} tone="neutral">
                {item}
              </Badge>
            ))}
          </div>
        </div>
      ) : null}
    </section>
  );
}

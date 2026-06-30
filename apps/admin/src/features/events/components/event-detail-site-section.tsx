'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { buildAppleMapsUrl, buildGoogleMapsUrl } from '@/features/events/lib/map-links';
import styles from './event-detail.module.css';

type EventDetailSiteSectionProps = {
  site: CleanupEventDetail['site'];
};

export function EventDetailSiteSection({ site }: EventDetailSiteSectionProps) {
  const t = useTranslations('events.detail');
  const tCommon = useTranslations('common');
  const googleMapsUrl = buildGoogleMapsUrl(site.latitude, site.longitude);
  const appleMapsUrl = buildAppleMapsUrl(site.latitude, site.longitude);

  return (
    <section className={styles.sectionCard}>
      <span className={styles.sectionLabel}>{t('siteLocation')}</span>
      <p className={styles.coordsValue}>
        {site.latitude.toFixed(6)}, {site.longitude.toFixed(6)}
      </p>
      {site.description ? <p className={styles.description}>{site.description}</p> : null}
      <div className={styles.mapLinks}>
        <a href={googleMapsUrl} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
          {tCommon('openInGoogleMaps')}
        </a>
        <a href={appleMapsUrl} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
          {tCommon('openInAppleMaps')}
        </a>
      </div>
      <Link href={`/dashboard/sites/${site.id}`} className={styles.siteLink}>
        {t('viewSiteDetails')}
      </Link>
    </section>
  );
}

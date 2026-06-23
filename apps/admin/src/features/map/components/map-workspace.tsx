'use client';

import { useTranslations } from 'next-intl';
import { PageHeader } from '@/components/ui';
import { SitesMap } from './sites-map-client';
import styles from './map-workspace.module.css';

export function MapWorkspace() {
  const t = useTranslations('map');

  return (
    <div className={styles.layout}>
      <PageHeader title={t('pageTitle')} description={t('pageDescription')} />
      <div className={styles.mapFrame}>
        <SitesMap />
      </div>
    </div>
  );
}

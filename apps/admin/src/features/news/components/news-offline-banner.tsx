'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import styles from './news-offline-banner.module.css';

type NewsOfflineBannerProps = {
  visible: boolean;
};

/** Renders only after mount so SSR/client HTML stay aligned. */
export function NewsOfflineBanner({ visible }: NewsOfflineBannerProps) {
  const t = useTranslations('news');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || !visible) return null;

  return (
    <p className={styles.banner} role="status">
      {t('offline.banner')}
    </p>
  );
}

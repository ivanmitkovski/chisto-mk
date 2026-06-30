'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import styles from './mfa-reminder-banner.module.css';

const DISMISS_STORAGE_KEY = 'chisto.admin.mfaReminder.dismissed';

type MfaReminderBannerProps = {
  mfaEnabled: boolean;
};

function readDismissedFromStorage(): boolean {
  if (typeof window === 'undefined') {
    return true;
  }
  return window.localStorage.getItem(DISMISS_STORAGE_KEY) === '1';
}

export function MfaReminderBanner({ mfaEnabled }: MfaReminderBannerProps) {
  const t = useTranslations('settings.mfa.banner');
  const router = useRouter();
  const [dismissed, setDismissed] = useState(readDismissedFromStorage);

  useEffect(() => {
    if (mfaEnabled) {
      return;
    }
    setDismissed(readDismissedFromStorage());
  }, [mfaEnabled]);

  if (mfaEnabled || dismissed) {
    return null;
  }

  function dismiss() {
    window.localStorage.setItem(DISMISS_STORAGE_KEY, '1');
    setDismissed(true);
  }

  return (
    <div className={styles.banner} role="status">
      <div className={styles.content}>
        <Icon name="shield" size={18} aria-hidden className={styles.icon} />
        <div className={styles.copy}>
          <p className={styles.title}>{t('title')}</p>
          <p className={styles.message}>{t('message')}</p>
        </div>
      </div>
      <div className={styles.actions}>
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={() => router.push('/dashboard/settings?section=security')}
        >
          {t('action')}
        </Button>
        <Button type="button" size="sm" variant="ghost" onClick={dismiss}>
          {t('dismiss')}
        </Button>
      </div>
    </div>
  );
}

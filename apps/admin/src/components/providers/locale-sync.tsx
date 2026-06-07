'use client';

import { useLayoutEffect } from 'react';
import { isAdminLocale, writeLocaleToStorage } from '@/lib/preferences/admin-locale';

type LocaleSyncProps = {
  serverLocale: string;
};

/** Mirror the SSR locale cookie into localStorage on hydrate. */
export function LocaleSync({ serverLocale }: LocaleSyncProps) {
  useLayoutEffect(() => {
    if (isAdminLocale(serverLocale)) {
      writeLocaleToStorage(serverLocale);
    }
  }, [serverLocale]);

  return null;
}

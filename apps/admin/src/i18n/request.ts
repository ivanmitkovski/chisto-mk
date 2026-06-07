import { cookies } from 'next/headers';
import { getRequestConfig } from 'next-intl/server';
import {
  ADMIN_LOCALE_COOKIE,
  DEFAULT_ADMIN_LOCALE,
  normalizeLocale,
} from '@/lib/preferences/admin-locale';
import { loadMessages } from './load-messages';

const ADMIN_TIME_ZONE = 'Europe/Skopje';

export default getRequestConfig(async () => {
  const cookieStore = await cookies();
  const raw = cookieStore.get(ADMIN_LOCALE_COOKIE)?.value;
  const locale = normalizeLocale(raw ?? DEFAULT_ADMIN_LOCALE);
  const messages = await loadMessages(locale);

  return {
    locale,
    messages,
    timeZone: ADMIN_TIME_ZONE,
  };
});

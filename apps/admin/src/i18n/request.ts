import { cookies, headers } from 'next/headers';
import { getRequestConfig } from 'next-intl/server';
import {
  ADMIN_LOCALE_COOKIE,
  DEFAULT_ADMIN_LOCALE,
  normalizeLocale,
} from '@/lib/preferences/admin-locale';
import { getNamespacesForPathname, loadAllMessages, loadMessages } from './load-messages';

const ADMIN_TIME_ZONE = 'Europe/Skopje';

export default getRequestConfig(async () => {
  const cookieStore = await cookies();
  const raw = cookieStore.get(ADMIN_LOCALE_COOKIE)?.value;
  const locale = normalizeLocale(raw ?? DEFAULT_ADMIN_LOCALE);
  const headerStore = await headers();
  const pathname = headerStore.get('x-pathname') ?? '';
  const namespaces = pathname ? getNamespacesForPathname(pathname) : null;
  const messages = namespaces ? await loadMessages(locale, namespaces) : await loadAllMessages(locale);

  return {
    locale,
    messages,
    timeZone: ADMIN_TIME_ZONE,
  };
});

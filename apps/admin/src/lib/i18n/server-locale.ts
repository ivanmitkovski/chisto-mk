import 'server-only';

import { cookies } from 'next/headers';
import {
  ADMIN_LOCALE_COOKIE,
  DEFAULT_ADMIN_LOCALE,
  getAcceptLanguageHeader,
  normalizeLocale,
  type AdminLocale,
} from '@/lib/preferences/admin-locale';

export async function getServerAdminLocale(): Promise<AdminLocale> {
  try {
    const cookieStore = await cookies();
    const raw = cookieStore.get(ADMIN_LOCALE_COOKIE)?.value;
    return normalizeLocale(raw ?? DEFAULT_ADMIN_LOCALE);
  } catch {
    return DEFAULT_ADMIN_LOCALE;
  }
}

export async function getServerAcceptLanguage(): Promise<string> {
  const locale = await getServerAdminLocale();
  return getAcceptLanguageHeader(locale);
}

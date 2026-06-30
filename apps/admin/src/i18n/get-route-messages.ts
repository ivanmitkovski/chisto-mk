'use server';

import { getLocale } from 'next-intl/server';
import { normalizeLocale } from '@/lib/preferences/admin-locale';
import { getNamespacesForPathname, loadMessages } from './load-messages';

export async function getRouteMessages(pathname: string) {
  const locale = normalizeLocale(await getLocale());
  const namespaces = getNamespacesForPathname(pathname);
  return loadMessages(locale, namespaces);
}

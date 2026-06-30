'use client';

import { useLocale } from 'next-intl';
import { ADMIN_LOCALE_BCP47, normalizeLocale } from '@/lib/preferences/admin-locale';

/** BCP-47 tag for Intl formatters from the active next-intl locale. */
export function useAdminBcp47Locale(): string {
  const locale = useLocale();
  return ADMIN_LOCALE_BCP47[normalizeLocale(locale)];
}

'use server';

import { cookies } from 'next/headers';
import { revalidatePath } from 'next/cache';
import {
  ADMIN_LOCALE_COOKIE,
  isAdminLocale,
  type AdminLocale,
} from '@/lib/preferences/admin-locale';

const LOCALE_COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

export async function setAdminLocale(locale: string): Promise<{ ok: true; locale: AdminLocale } | { ok: false }> {
  if (!isAdminLocale(locale)) {
    return { ok: false };
  }

  const cookieStore = await cookies();
  cookieStore.set(ADMIN_LOCALE_COOKIE, locale, {
    path: '/',
    maxAge: LOCALE_COOKIE_MAX_AGE,
    sameSite: 'lax',
  });
  revalidatePath('/', 'layout');
  return { ok: true, locale };
}

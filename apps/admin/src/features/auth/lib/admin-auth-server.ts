import { cookies } from 'next/headers';
import { ADMIN_AUTH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';

export async function getAdminAuthTokenFromCookies(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_AUTH_COOKIE_KEY)?.value ?? null;
}


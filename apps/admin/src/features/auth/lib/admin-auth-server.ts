import { cookies } from 'next/headers';

const ADMIN_AUTH_COOKIE_KEY = 'chisto_admin_token';

export async function getAdminAuthTokenFromCookies(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_AUTH_COOKIE_KEY)?.value ?? null;
}


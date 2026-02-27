import { apiFetch } from '@/lib/api';
import type { AuthResponse } from './types';

const ADMIN_AUTH_COOKIE_KEY = 'chisto_admin_token';

export async function loginAdmin(email: string, password: string): Promise<void> {
  const response = await apiFetch<AuthResponse>('/auth/admin/login', {
    method: 'POST',
    body: { email, password },
  });

  if (typeof document !== 'undefined') {
    const encodedName = encodeURIComponent(ADMIN_AUTH_COOKIE_KEY);
    const encodedValue = encodeURIComponent(response.accessToken);
    const secureFlag = window.location.protocol === 'https:' ? '; Secure' : '';

    document.cookie = `${encodedName}=${encodedValue}; Path=/; SameSite=Lax${secureFlag}`;
  }
}


import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type MeProfile = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  role: string;
  mfaEnabled?: boolean;
};

export async function getMeProfile(): Promise<MeProfile> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch<MeProfile>('/auth/me', {
    method: 'GET',
    authToken: token,
  });
}

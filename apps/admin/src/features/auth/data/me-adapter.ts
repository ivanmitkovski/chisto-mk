import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

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
  return serverAuthenticatedFetch<MeProfile>('/auth/me', {
    method: 'GET',
  });
}

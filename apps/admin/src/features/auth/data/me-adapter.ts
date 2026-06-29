import 'server-only';

import { cache } from 'react';
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

/** Deduplicated per RSC request (layout + page + permission checks share one /auth/me). */
export const getMeProfile = cache(async (): Promise<MeProfile> => {
  return serverAuthenticatedFetch<MeProfile>('/auth/me', {
    method: 'GET',
  });
});

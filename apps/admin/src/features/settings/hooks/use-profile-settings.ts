'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { ApiError } from '@/lib/api';
import type { MeProfile } from '@/features/auth/data/me-adapter';

export function useProfileSettings(initialMe: MeProfile) {
  const t = useTranslations('settings.profile');
  const tCommon = useTranslations('common');
  const [baseline, setBaseline] = useState({
    firstName: initialMe.firstName,
    lastName: initialMe.lastName,
  });
  const [firstName, setFirstName] = useState(initialMe.firstName);
  const [lastName, setLastName] = useState(initialMe.lastName);
  const { showToast, clearToast } = useToast();
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setBaseline({ firstName: initialMe.firstName, lastName: initialMe.lastName });
    setFirstName(initialMe.firstName);
    setLastName(initialMe.lastName);
  }, [initialMe.firstName, initialMe.lastName]);

  const hasChanges = firstName !== baseline.firstName || lastName !== baseline.lastName;

  async function saveProfile(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    clearToast();
    try {
      await adminBrowserFetch('/auth/me', {
        method: 'PATCH',
        body: { firstName, lastName },
      });
      setBaseline({ firstName, lastName });
      showToast({ tone: 'success', title: tCommon('saved'), message: t('savedToast') });
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : tCommon('saveFailed');
      showToast({ tone: 'warning', title: t('errorToast'), message: msg });
    } finally {
      setBusy(false);
    }
  }

  return {
    firstName,
    setFirstName,
    lastName,
    setLastName,
    busy,
    hasChanges,
    saveProfile,
  };
}

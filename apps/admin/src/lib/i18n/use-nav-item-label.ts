'use client';

import { useTranslations } from 'next-intl';

export function useNavItemLabel(key: string): string {
  const t = useTranslations('nav');
  return t(key as Parameters<typeof t>[0]);
}

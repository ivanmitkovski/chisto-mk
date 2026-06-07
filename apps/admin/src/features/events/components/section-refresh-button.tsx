'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';

type SectionRefreshButtonProps = {
  label?: string;
};

/** For server-rendered error sections: triggers Next.js `router.refresh()` to retry RSC fetches. */
export function SectionRefreshButton({ label }: SectionRefreshButtonProps) {
  const router = useRouter();
  const t = useTranslations('common');
  return (
    <Button type="button" variant="outline" size="sm" onClick={() => router.refresh()}>
      {label ?? t('retry')}
    </Button>
  );
}

'use client';

import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui';

type SectionRefreshButtonProps = {
  label?: string;
};

/** For server-rendered error sections: triggers Next.js `router.refresh()` to retry RSC fetches. */
export function SectionRefreshButton({ label = 'Try again' }: SectionRefreshButtonProps) {
  const router = useRouter();
  return (
    <Button type="button" variant="outline" size="sm" onClick={() => router.refresh()}>
      {label}
    </Button>
  );
}

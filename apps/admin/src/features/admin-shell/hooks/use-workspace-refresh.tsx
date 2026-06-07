'use client';

import { useCallback, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function useWorkspaceRefresh() {
  const router = useRouter();
  const [isRefreshing, startTransition] = useTransition();

  const refresh = useCallback(() => {
    startTransition(() => {
      router.refresh();
    });
  }, [router]);

  return { refresh, isRefreshing };
}

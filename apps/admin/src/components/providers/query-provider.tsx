'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

/** Semi-static admin lists: longer stale window; disable focus refetch by default to avoid dashboard churn (override per query if needed). */
const defaultOptions = {
  defaultOptions: {
    queries: {
      staleTime: 90_000,
      gcTime: 600_000,
      refetchOnWindowFocus: false,
      refetchInterval: false as const,
    },
  },
};

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient(defaultOptions));
  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}

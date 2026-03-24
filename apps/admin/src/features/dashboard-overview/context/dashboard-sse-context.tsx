'use client';

import {
  createContext,
  useCallback,
  useContext,
  useState,
  type ReactNode,
} from 'react';
import { Snack } from '@/components/ui';
import type { SnackState } from '@/components/ui';

type DashboardSSEContextValue = {
  connected: boolean;
  setConnected: (v: boolean) => void;
  showRefreshToast: (message: string) => void;
};

const DashboardSSEContext = createContext<DashboardSSEContextValue | null>(null);

export function useDashboardSSE() {
  const ctx = useContext(DashboardSSEContext);
  return ctx;
}

type DashboardSSEProviderProps = {
  children: ReactNode;
};

export function DashboardSSEProvider({ children }: DashboardSSEProviderProps) {
  const [connected, setConnected] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const showRefreshToast = useCallback((message: string) => {
    setSnack({
      tone: 'success',
      title: 'Live update',
      message,
    });
  }, []);

  const clearSnack = useCallback(() => setSnack(null), []);

  const value: DashboardSSEContextValue = {
    connected,
    setConnected,
    showRefreshToast,
  };

  return (
    <DashboardSSEContext.Provider value={value}>
      {children}
      <Snack snack={snack} onClose={clearSnack} durationMs={2500} />
    </DashboardSSEContext.Provider>
  );
}

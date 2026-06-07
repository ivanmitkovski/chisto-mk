'use client';

import {
  createContext,
  useCallback,
  useContext,
  useState,
  type ReactNode,
} from 'react';
import { useToast } from '@/components/ui';

type DashboardSSEContextValue = {
  connected: boolean;
  disconnected: boolean;
  setConnected: (value: boolean) => void;
  setDisconnected: (value: boolean) => void;
  reconnectNonce: number;
  requestReconnect: () => void;
  lastUpdatedAt: number;
  touchLastUpdated: () => void;
  showRefreshToast: (message: string) => void;
};

const DashboardSSEContext = createContext<DashboardSSEContextValue | null>(null);

export function useDashboardSSE() {
  return useContext(DashboardSSEContext);
}

type DashboardSSEProviderProps = {
  children: ReactNode;
};

export function DashboardSSEProvider({ children }: DashboardSSEProviderProps) {
  const { showToast } = useToast();
  const [connected, setConnected] = useState(false);
  const [disconnected, setDisconnected] = useState(false);
  const [reconnectNonce, setReconnectNonce] = useState(0);
  const [lastUpdatedAt, setLastUpdatedAt] = useState(() => Date.now());

  const touchLastUpdated = useCallback(() => {
    setLastUpdatedAt(Date.now());
  }, []);

  const requestReconnect = useCallback(() => {
    setDisconnected(false);
    setReconnectNonce((value) => value + 1);
  }, []);

  const showRefreshToast = useCallback(
    (message: string) => {
      touchLastUpdated();
      showToast({
        tone: 'success',
        title: 'Live update',
        message,
      });
    },
    [showToast, touchLastUpdated],
  );

  const value: DashboardSSEContextValue = {
    connected,
    disconnected,
    setConnected,
    setDisconnected,
    reconnectNonce,
    requestReconnect,
    lastUpdatedAt,
    touchLastUpdated,
    showRefreshToast,
  };

  return (
    <DashboardSSEContext.Provider value={value}>
      {children}
    </DashboardSSEContext.Provider>
  );
}

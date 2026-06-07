'use client';

import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { Snack, type SnackState } from '../snack';

type QueuedToast = SnackState & { id: string };

type ToastContextValue = {
  showToast: (toast: SnackState) => void;
  clearToast: () => void;
};

const ToastContext = createContext<ToastContextValue | null>(null);

function createToastId() {
  return `toast-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function isErrorToast(toast: SnackState) {
  return toast.tone === 'error' || toast.tone === 'danger';
}

function toastDurationMs(toast: SnackState) {
  const textLength = `${toast.title} ${toast.message}`.trim().length;
  const baseMs = isErrorToast(toast) ? 5200 : 3600;
  const extraMs = Math.min(2400, Math.max(0, textLength - 48) * 40);
  return baseMs + extraMs;
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [queue, setQueue] = useState<QueuedToast[]>([]);
  const [activeToast, setActiveToast] = useState<QueuedToast | null>(null);

  const showToast = useCallback((nextToast: SnackState) => {
    setQueue((prev) => [...prev, { ...nextToast, id: createToastId() }]);
  }, []);

  const clearToast = useCallback(() => {
    setActiveToast(null);
  }, []);

  useEffect(() => {
    if (activeToast !== null || queue.length === 0) return;
    const [next, ...rest] = queue;
    setActiveToast(next);
    setQueue(rest);
  }, [activeToast, queue]);

  const value = useMemo(() => ({ showToast, clearToast }), [clearToast, showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <Snack
        snack={activeToast}
        onClose={clearToast}
        durationMs={activeToast ? toastDurationMs(activeToast) : 3600}
      />
    </ToastContext.Provider>
  );
}

export function useToast(): ToastContextValue {
  const value = useContext(ToastContext);
  if (!value) {
    throw new Error('useToast must be used inside ToastProvider');
  }
  return value;
}

'use client';

import { createContext, ReactNode, useCallback, useContext, useMemo, useState } from 'react';
import { Snack, type SnackState } from '../snack';

type ToastContextValue = {
  showToast: (toast: SnackState) => void;
  clearToast: () => void;
};

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toast, setToast] = useState<SnackState | null>(null);
  const showToast = useCallback((nextToast: SnackState) => setToast(nextToast), []);
  const clearToast = useCallback(() => setToast(null), []);
  const value = useMemo(() => ({ showToast, clearToast }), [clearToast, showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <Snack snack={toast} onClose={clearToast} />
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

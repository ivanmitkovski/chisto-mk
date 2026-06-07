'use client';

import { useEffect } from 'react';
import { clientLogger } from './client-logger';

export function GlobalErrorReporter() {
  useEffect(() => {
    const onError = (event: ErrorEvent) => {
      clientLogger.error('window_error', {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
      });
    };

    const onUnhandledRejection = (event: PromiseRejectionEvent) => {
      const reason = event.reason;
      clientLogger.error('unhandled_rejection', {
        message: reason instanceof Error ? reason.message : String(reason),
        ...(reason instanceof Error ? { name: reason.name } : {}),
      });
    };

    window.addEventListener('error', onError);
    window.addEventListener('unhandledrejection', onUnhandledRejection);
    return () => {
      window.removeEventListener('error', onError);
      window.removeEventListener('unhandledrejection', onUnhandledRejection);
    };
  }, []);

  return null;
}

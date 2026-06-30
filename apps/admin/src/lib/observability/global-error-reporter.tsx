'use client';

import { useEffect } from 'react';
import { clientLogger } from './client-logger';
import { describeClientRejection, isDomLoadEventRejection } from './normalize-client-rejection';

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
      const message = describeClientRejection(reason);

      if (isDomLoadEventRejection(reason)) {
        // Webpack/Next chunk or CSS load failures reject with a DOM Event — not an Error.
        // Log clearly and avoid surfacing "[object Event]" in the dev overlay.
        event.preventDefault();
        clientLogger.error('asset_load_failed', { message, kind: reason.type });
        return;
      }

      clientLogger.error('unhandled_rejection', {
        message,
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

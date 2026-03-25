type NewReportListener = (payload: { reportId: string; atMs: number }) => void;

const newReportListeners = new Set<NewReportListener>();
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

export function emitNewReportSignal(reportId: string): void {
  const payload = { reportId, atMs: Date.now() };
  if (isRealtimeDebugEnabled()) {
    // Development aid for tracing the realtime pipeline in the browser.
    console.debug('[realtime] emitNewReportSignal', payload);
  }
  for (const listener of newReportListeners) {
    listener(payload);
  }
}

export function subscribeNewReportSignal(listener: NewReportListener): () => void {
  newReportListeners.add(listener);
  if (isRealtimeDebugEnabled()) {
    console.debug('[realtime] subscribeNewReportSignal count=', newReportListeners.size);
  }
  return () => {
    newReportListeners.delete(listener);
    if (isRealtimeDebugEnabled()) {
      console.debug('[realtime] unsubscribeNewReportSignal count=', newReportListeners.size);
    }
  };
}

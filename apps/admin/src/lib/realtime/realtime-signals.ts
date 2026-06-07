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

type CheckInRiskListener = (payload: { signalId: string; atMs: number }) => void;
const checkInRiskListeners = new Set<CheckInRiskListener>();

export function emitCheckInRiskSignal(signalId: string): void {
  const payload = { signalId, atMs: Date.now() };
  if (isRealtimeDebugEnabled()) {
    console.debug('[realtime] emitCheckInRiskSignal', payload);
  }
  for (const listener of checkInRiskListeners) {
    listener(payload);
  }
}

export function subscribeCheckInRiskSignal(listener: CheckInRiskListener): () => void {
  checkInRiskListeners.add(listener);
  return () => {
    checkInRiskListeners.delete(listener);
  };
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

export type ReportViewerPresenceEntry = {
  sessionId: string;
  userId: string;
  displayName: string;
};

type ReportViewersUpdatedListener = (payload: {
  reportId: string;
  viewers: ReportViewerPresenceEntry[];
  atMs: number;
}) => void;

const reportViewersUpdatedListeners = new Set<ReportViewersUpdatedListener>();

export function emitReportViewersUpdated(
  reportId: string,
  viewers: ReportViewerPresenceEntry[],
): void {
  const payload = { reportId, viewers, atMs: Date.now() };
  if (isRealtimeDebugEnabled()) {
    console.debug('[realtime] emitReportViewersUpdated', payload);
  }
  for (const listener of reportViewersUpdatedListeners) {
    listener(payload);
  }
}

export function subscribeReportViewersUpdated(listener: ReportViewersUpdatedListener): () => void {
  reportViewersUpdatedListeners.add(listener);
  return () => {
    reportViewersUpdatedListeners.delete(listener);
  };
}

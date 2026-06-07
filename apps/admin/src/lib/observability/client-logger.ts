'use client';

import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import type { LogLevel } from './types';

type PendingEvent = {
  level: LogLevel;
  message: string;
  requestId?: string;
  context?: Record<string, unknown>;
};

const FLUSH_INTERVAL_MS = 2_000;
const MAX_BATCH = 20;

const queue: PendingEvent[] = [];
let flushTimer: ReturnType<typeof setTimeout> | null = null;

function scheduleFlush(): void {
  if (flushTimer !== null) return;
  flushTimer = setTimeout(() => {
    flushTimer = null;
    void flushClientLogs();
  }, FLUSH_INTERVAL_MS);
}

async function flushClientLogs(): Promise<void> {
  if (queue.length === 0) return;
  const batch = queue.splice(0, MAX_BATCH);
  try {
    await fetch('/api/admin/telemetry', {
      method: 'POST',
      credentials: 'include',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...getAdminCsrfHeaders(),
      },
      body: JSON.stringify({ events: batch }),
      keepalive: true,
    });
  } catch {
    // Best-effort client telemetry; avoid recursive logging.
  }
  if (queue.length > 0) scheduleFlush();
}

function enqueue(level: LogLevel, message: string, context?: Record<string, unknown> & { requestId?: string }): void {
  const { requestId, ...rest } = context ?? {};
  queue.push({
    level,
    message,
    ...(requestId !== undefined ? { requestId } : {}),
    ...(Object.keys(rest).length > 0 ? { context: rest } : {}),
  });
  if (queue.length >= MAX_BATCH) {
    void flushClientLogs();
    return;
  }
  scheduleFlush();
}

export const clientLogger = {
  info: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    enqueue('info', message, context),
  warn: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    enqueue('warn', message, context),
  error: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    enqueue('error', message, context),
  flush: flushClientLogs,
};

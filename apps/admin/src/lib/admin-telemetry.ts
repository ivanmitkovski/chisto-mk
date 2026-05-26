import { getAdminCsrfHeaders } from '@/features/auth/lib/admin-auth';

export function recordAdminTelemetry(event: {
  type: 'route_load_failure' | 'bff_proxy_error' | 'sse_reconnect_loop' | 'mutation_failure' | 'csp_report_sample';
  route?: string;
  message?: string;
  metadata?: Record<string, unknown>;
}) {
  if (typeof window === 'undefined') return;
  fetch('/api/admin/telemetry', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    body: JSON.stringify(event),
    credentials: 'include',
    keepalive: true,
  }).catch(() => undefined);
}

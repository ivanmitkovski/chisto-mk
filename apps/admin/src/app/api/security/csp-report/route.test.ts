import { describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';

describe('csp-report route', () => {
  it('accepts CSP reports and emits structured logs', async () => {
    const emit = vi.fn();
    const { setTelemetrySink } = await import('@/lib/observability');
    setTelemetrySink({ emit });

    const { POST } = await import('./route');
    const request = new NextRequest('https://admin.chisto.mk/api/security/csp-report', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        'csp-report': {
          'document-uri': 'https://admin.chisto.mk/dashboard',
          'violated-directive': 'script-src',
        },
      }),
    });

    const response = await POST(request);

    expect(response.status).toBe(202);
    expect(emit).toHaveBeenCalledWith(
      expect.objectContaining({
        level: 'warn',
        message: 'csp_violation',
      }),
    );
  });
});

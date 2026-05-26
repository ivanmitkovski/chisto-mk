import { describe, expect, it } from 'vitest';
import { NextRequest } from 'next/server';
import { ADMIN_CSRF_HEADER } from '@/features/auth/lib/auth-constants';
import { createBackendProxyHeaders } from './admin-api-with-refresh';

describe('createBackendProxyHeaders', () => {
  it('drops browser/internal headers and keeps only backend-safe headers', () => {
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/users', {
      method: 'PATCH',
      headers: {
        accept: 'application/json',
        cookie: 'secret=true',
        host: 'admin.chisto.mk',
        [ADMIN_CSRF_HEADER]: 'csrf-token',
        'x-nextjs-data': '1',
        'if-match': '"etag"',
      },
    });

    const headers = createBackendProxyHeaders(request, 'access-token');

    expect(headers.get('Authorization')).toBe('Bearer access-token');
    expect(headers.get('if-match')).toBe('"etag"');
    expect(headers.get('cookie')).toBeNull();
    expect(headers.get('host')).toBeNull();
    expect(headers.get(ADMIN_CSRF_HEADER)).toBeNull();
    expect(headers.get('x-nextjs-data')).toBeNull();
    expect(headers.get('X-Idempotency-Key')).toBeTruthy();
  });
});

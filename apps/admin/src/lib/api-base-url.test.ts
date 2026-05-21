import { describe, expect, it, vi } from 'vitest';
import { getApiBaseUrl, getApiOrigin } from './api-base-url';

describe('getApiBaseUrl', () => {
  it('appends /v1 when missing', () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'https://api.chisto.mk');
    expect(getApiBaseUrl()).toBe('https://api.chisto.mk/v1');
  });

  it('does not double-append /v1', () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'https://api.chisto.mk/v1/');
    expect(getApiBaseUrl()).toBe('https://api.chisto.mk/v1');
  });

  it('defaults localhost to /v1', () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', '');
    expect(getApiBaseUrl()).toBe('http://localhost:3000/v1');
  });
});

describe('getApiOrigin', () => {
  it('strips /v1 for health checks', () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'https://api.chisto.mk');
    expect(getApiOrigin()).toBe('https://api.chisto.mk');
  });
});

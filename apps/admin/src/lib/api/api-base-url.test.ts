import { describe, expect, it, vi } from 'vitest';
import {
  getApiBaseUrl,
  getApiConnectionErrorMessage,
  getApiOrigin,
  isLocalApiBaseUrl,
} from './api-base-url';

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

describe('getApiConnectionErrorMessage', () => {
  it('mentions local dev when API base is localhost', () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', '');
    vi.stubEnv('SERVER_API_BASE_URL', '');
    expect(isLocalApiBaseUrl()).toBe(true);
    expect(getApiConnectionErrorMessage(false)).toContain('localhost:3000');
  });

  it('mentions remote origin when API base is configured', () => {
    vi.stubEnv('SERVER_API_BASE_URL', 'https://api.chisto.mk');
    expect(isLocalApiBaseUrl()).toBe(false);
    expect(getApiConnectionErrorMessage(true)).toContain('api.chisto.mk');
  });
});

import { afterEach, describe, expect, it, vi } from 'vitest';
import { buildAdminContentSecurityPolicy } from './content-security-policy';

describe('buildAdminContentSecurityPolicy', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it('allows the API origin for nested /v1 requests', () => {
    vi.stubEnv('SERVER_API_BASE_URL', 'https://api.chisto.mk/v1');

    const csp = buildAdminContentSecurityPolicy('test-nonce', false);
    const connectSrc = csp.split('; ').find((directive) => directive.startsWith('connect-src'));

    expect(connectSrc).toContain('https://api.chisto.mk');
    expect(connectSrc).not.toContain('https://api.chisto.mk/v1');
  });
});

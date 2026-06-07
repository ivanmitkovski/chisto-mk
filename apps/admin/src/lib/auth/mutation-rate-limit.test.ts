import { describe, expect, it } from 'vitest';
import { buildMutationRateLimitKey, checkMutationRateLimit } from '@/lib/auth/mutation-rate-limit';
import { NextRequest } from 'next/server';

function makeRequest(method = 'POST'): NextRequest {
  return new NextRequest('http://localhost/api/proxy/reports', { method });
}

describe('mutation-rate-limit', () => {
  it('allows GET without counting', async () => {
    const request = makeRequest('GET');
    expect(await checkMutationRateLimit(request, 'token-a')).toBe(true);
  });

  it('builds stable keys from forwarded ip and token', () => {
    const request = new NextRequest('http://localhost/', {
      headers: { 'x-forwarded-for': '1.2.3.4, 5.6.7.8' },
    });
    expect(buildMutationRateLimitKey(request, 'abc')).toBe('1.2.3.4:abc');
  });

  it('falls back to in-memory limiter when redis is unavailable', async () => {
    const request = makeRequest('POST');
    const token = `mem-test-${Date.now()}`;
    for (let i = 0; i < 120; i += 1) {
      expect(await checkMutationRateLimit(request, token)).toBe(true);
    }
    expect(await checkMutationRateLimit(request, token)).toBe(false);
  });
});

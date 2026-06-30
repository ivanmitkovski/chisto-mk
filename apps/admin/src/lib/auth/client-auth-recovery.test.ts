/**
 * @vitest-environment jsdom
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { recoverFromUnauthorized } from './client-auth-recovery';

describe('recoverFromUnauthorized', () => {
  const originalLocation = window.location;

  beforeEach(() => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({ ok: false, status: 403 }),
    );
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: { assign: vi.fn() },
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: originalLocation,
    });
  });

  it('retries once on 403 and does not sign out when retry succeeds', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 403 })
      .mockResolvedValueOnce({ ok: true, status: 200 });
    vi.stubGlobal('fetch', fetchMock);

    const result = await recoverFromUnauthorized();

    expect(result).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(window.location.assign).not.toHaveBeenCalled();
  });

  it('does not sign out on 429 transient failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 429 }));

    const result = await recoverFromUnauthorized();

    expect(result).toBe(false);
    expect(window.location.assign).not.toHaveBeenCalled();
  });

  it('does not sign out on network failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network')));

    const result = await recoverFromUnauthorized();

    expect(result).toBe(false);
    expect(window.location.assign).not.toHaveBeenCalled();
  });

  it('signs out only on definitive 401', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 401 }));

    const result = await recoverFromUnauthorized();

    expect(result).toBe(false);
    expect(window.location.assign).toHaveBeenCalledWith('/login');
  });
});

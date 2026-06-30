import { afterEach, describe, expect, it, vi } from 'vitest';
import { patchReportStatus } from './patch-report-status';

describe('patchReportStatus', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('sends default reject reason when action is reject and reason empty', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({}),
    });
    vi.stubGlobal('fetch', fetchMock);

    const result = await patchReportStatus('rep_1', 'DELETED', 'reject', '   ');

    expect(result).toEqual({ ok: true, status: 200 });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(init.method).toBe('PATCH');
    expect(JSON.parse(init.body as string)).toEqual({
      status: 'DELETED',
      reason: 'Rejected by moderator.',
    });
  });

  it('returns structured failure when response is not ok', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: false,
      status: 422,
      json: async () => ({ message: 'Invalid transition' }),
    });
    vi.stubGlobal('fetch', fetchMock);

    const result = await patchReportStatus('rep_1', 'APPROVED', 'approve');

    expect(result).toEqual({
      ok: false,
      status: 422,
      message: 'Invalid transition',
    });
  });
});

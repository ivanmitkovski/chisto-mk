import { ConfigService } from '@nestjs/config';
import { EmailPostmarkTransportService } from '../../src/email/services/email-postmark-transport.service';
import type { EmailSendPayload } from '../../src/email/types/email-transport.types';

describe('EmailPostmarkTransportService', () => {
  const basePayload: EmailSendPayload = {
    to: 'user@test.mk',
    fromHeader: 'Chisto.mk <no-reply@chisto.mk>',
    subject: 'Test',
    text: 'plain',
    html: '<p>html</p>',
    listUnsubscribeUrl: 'https://api.chisto.mk/notifications/email/unsubscribe?token=abc',
    templateId: 'welcome',
  };

  const config = (token?: string) =>
    ({
      get: (key: string) => (key === 'POSTMARK_SERVER_TOKEN' ? token : undefined),
    }) as ConfigService;

  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('returns false when server token is missing', async () => {
    const svc = new EmailPostmarkTransportService(config());
    await expect(svc.send(basePayload)).resolves.toBe(false);
    expect(global.fetch).toBe(originalFetch);
  });

  it('sends with List-Unsubscribe headers on success', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ MessageID: 'msg-123' }),
    });
    global.fetch = fetchMock as typeof fetch;

    const svc = new EmailPostmarkTransportService(config('pm-test-token'));
    await expect(svc.send(basePayload)).resolves.toBe(true);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://api.postmarkapp.com/email');
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>)['X-Postmark-Server-Token']).toBe('pm-test-token');
    const body = JSON.parse(String(init.body)) as {
      From: string;
      MessageStream: string;
      Headers: Array<{ Name: string; Value: string }>;
    };
    expect(body.From).toBe(basePayload.fromHeader);
    expect(body.MessageStream).toBe('outbound');
    expect(body.Headers).toEqual(
      expect.arrayContaining([
        { Name: 'List-Unsubscribe', Value: `<${basePayload.listUnsubscribeUrl}>` },
        { Name: 'List-Unsubscribe-Post', Value: 'List-Unsubscribe=One-Click' },
      ]),
    );
  });

  it('retries once on 429 then succeeds', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 429, text: async () => 'rate limited' })
      .mockResolvedValueOnce({ ok: true, json: async () => ({ MessageID: 'msg-456' }) });
    global.fetch = fetchMock as typeof fetch;

    const svc = new EmailPostmarkTransportService(config('pm-test-token'));
    await expect(svc.send(basePayload)).resolves.toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('returns false on 422 without retry', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: false,
      status: 422,
      text: async () => 'inactive recipient',
    });
    global.fetch = fetchMock as typeof fetch;

    const svc = new EmailPostmarkTransportService(config('pm-test-token'));
    await expect(svc.send(basePayload)).resolves.toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('returns false on 401 without retry', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: false,
      status: 401,
      text: async () => 'invalid token',
    });
    global.fetch = fetchMock as typeof fetch;

    const svc = new EmailPostmarkTransportService(config('pm-test-token'));
    await expect(svc.send(basePayload)).resolves.toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});

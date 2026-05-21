/// <reference types="jest" />

import { buildMultipartAlternativeMime } from '../../src/email/email-mime-builder';

describe('buildMultipartAlternativeMime', () => {
  it('includes ASCII subject as-is', () => {
    const raw = buildMultipartAlternativeMime({
      fromHeader: 'Chisto.mk <no-reply@chisto.mk>',
      to: 'user@example.com',
      subject: 'Hello',
      textBody: 'plain',
      htmlBody: '<p>hi</p>',
    });
    const s = Buffer.from(raw).toString('utf8');
    expect(s).toContain('Subject: Hello');
    expect(s).toContain('Content-Type: multipart/alternative');
    expect(s).toContain('Content-Transfer-Encoding: base64');
  });

  it('RFC2047-encodes non-ASCII subject', () => {
    const raw = buildMultipartAlternativeMime({
      fromHeader: 'Chisto.mk <no-reply@chisto.mk>',
      to: 'user@example.com',
      subject: 'Здраво свету',
      textBody: 'x',
      htmlBody: '<p>x</p>',
    });
    const s = Buffer.from(raw).toString('utf8');
    expect(s).toMatch(/^Subject: =\?UTF-8\?B\?/m);
  });

  it('adds List-Unsubscribe headers when URL provided', () => {
    const url = 'https://api.chisto.mk/notifications/email/unsubscribe?token=abc';
    const raw = buildMultipartAlternativeMime({
      fromHeader: 'Chisto.mk <no-reply@chisto.mk>',
      to: 'user@example.com',
      subject: 'S',
      textBody: 't',
      htmlBody: '<p>h</p>',
      listUnsubscribeUrl: url,
    });
    const s = Buffer.from(raw).toString('utf8');
    expect(s).toContain(`List-Unsubscribe: <${url}>`);
    expect(s).toContain('List-Unsubscribe-Post: List-Unsubscribe=One-Click');
  });
});

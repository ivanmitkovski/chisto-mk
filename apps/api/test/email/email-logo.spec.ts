/// <reference types="jest" />

import { EMAIL_LOGO_CONTENT_ID } from '../../src/email/email.constants';
import {
  resolveEmailLogo,
  resolveEmailLogoPreviewSrc,
  resetEmbeddedEmailLogoCache,
  resolveEmailLogoSrc,
} from '../../src/email/email-logo';

describe('email-logo', () => {
  beforeEach(() => {
    resetEmbeddedEmailLogoCache();
  });

  it('attaches bundled PNG via CID by default', () => {
    const resolved = resolveEmailLogo({});
    expect(resolved.logoUrl).toBe(`cid:${EMAIL_LOGO_CONTENT_ID}`);
    expect(resolved.inlineAttachment?.contentId).toBe(EMAIL_LOGO_CONTENT_ID);
    expect(resolved.inlineAttachment?.contentType).toBe('image/png');
    expect(resolved.inlineAttachment?.contentBase64.length).toBeGreaterThan(100);
  });

  it('resolveEmailLogoSrc returns CID src', () => {
    expect(resolveEmailLogoSrc({})).toBe(`cid:${EMAIL_LOGO_CONTENT_ID}`);
  });

  it('resolveEmailLogoPreviewSrc uses data URI for local HTML preview', () => {
    const src = resolveEmailLogoPreviewSrc({});
    expect(src.startsWith('data:image/png;base64,')).toBe(true);
  });

  it('uses EMAIL_LOGO_URL when configured', () => {
    const resolved = resolveEmailLogo({ logo: 'https://cdn.example.test/logo.png' });
    expect(resolved.logoUrl).toBe('https://cdn.example.test/logo.png');
    expect(resolved.inlineAttachment).toBeUndefined();
  });
});

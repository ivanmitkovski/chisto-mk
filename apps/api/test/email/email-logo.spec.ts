/// <reference types="jest" />

import {
  getEmbeddedEmailLogoDataUri,
  resetEmbeddedEmailLogoCache,
  resolveEmailLogoSrc,
} from '../../src/email/email-logo';

describe('email-logo', () => {
  beforeEach(() => {
    resetEmbeddedEmailLogoCache();
  });

  it('embeds bundled PNG by default', () => {
    const src = resolveEmailLogoSrc({});
    expect(src.startsWith('data:image/png;base64,')).toBe(true);
    expect(src.length).toBeGreaterThan(100);
  });

  it('uses EMAIL_LOGO_URL when configured', () => {
    const src = resolveEmailLogoSrc({ logo: 'https://cdn.example.test/logo.png' });
    expect(src).toBe('https://cdn.example.test/logo.png');
  });

  it('getEmbeddedEmailLogoDataUri returns stable cache', () => {
    const a = getEmbeddedEmailLogoDataUri();
    const b = getEmbeddedEmailLogoDataUri();
    expect(a).toBe(b);
    expect(a).toMatch(/^data:image\/png;base64,/);
  });
});

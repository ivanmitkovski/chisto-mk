import { describe, expect, it } from 'vitest';
import {
  buildAdminContentSecurityPolicy,
  buildAdminReportOnlyContentSecurityPolicy,
} from './content-security-policy';

describe('buildAdminContentSecurityPolicy', () => {
  it('keeps browser connections on the BFF surface only', () => {
    const csp = buildAdminContentSecurityPolicy('test-nonce', false);
    const connectSrc = csp.split('; ').find((directive) => directive.startsWith('connect-src'));

    expect(connectSrc).toContain("connect-src 'self'");
    expect(connectSrc).not.toContain('api.chisto.mk');
  });

  it('allows uploaded news video playback from HTTPS and blob previews', () => {
    const csp = buildAdminContentSecurityPolicy('test-nonce', false);
    const mediaSrc = csp.split('; ').find((directive) => directive.startsWith('media-src'));

    expect(mediaSrc).toContain("media-src 'self'");
    expect(mediaSrc).toContain('blob:');
    expect(mediaSrc).toContain('https:');
    expect(mediaSrc).toContain('chisto-dev-media.s3.eu-central-1.amazonaws.com');
  });

  it('allows trusted news video embeds in frame-src', () => {
    const csp = buildAdminContentSecurityPolicy('test-nonce', false);
    const frameSrc = csp.split('; ').find((directive) => directive.startsWith('frame-src'));

    expect(frameSrc).toContain("frame-src 'self'");
    expect(frameSrc).toContain('https://www.youtube-nocookie.com');
    expect(frameSrc).toContain('https://player.vimeo.com');
  });

  it('keeps the strict report-only policy available for explicit audits', () => {
    const csp = buildAdminReportOnlyContentSecurityPolicy('test-nonce', false);

    expect(csp).toContain("style-src 'self'");
    expect(csp).toContain("require-trusted-types-for 'script'");
  });
});

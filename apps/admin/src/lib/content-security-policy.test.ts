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

  it('keeps the strict report-only policy available for explicit audits', () => {
    const csp = buildAdminReportOnlyContentSecurityPolicy('test-nonce', false);

    expect(csp).toContain("style-src 'self'");
    expect(csp).toContain("require-trusted-types-for 'script'");
  });
});

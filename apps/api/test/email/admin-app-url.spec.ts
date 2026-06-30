/// <reference types="jest" />

import { ConfigService } from '@nestjs/config';
import {
  buildAdminAcceptInviteUrl,
  buildAdminDeepLink,
  resolveAdminAppBaseUrl,
} from '../../src/email/util/admin-app-url';

describe('admin-app-url', () => {
  function configWith(values: Record<string, string | undefined>): ConfigService {
    return {
      get: (key: string) => values[key],
    } as ConfigService;
  }

  it('defaults to admin.chisto.mk when env is unset', () => {
    expect(resolveAdminAppBaseUrl(configWith({}))).toBe('https://admin.chisto.mk');
    expect(buildAdminDeepLink(configWith({}), '/dashboard/reports?reportId=r1')).toBe(
      'https://admin.chisto.mk/dashboard/reports?reportId=r1',
    );
  });

  it('never returns localhost when env is unset', () => {
    const reportUrl = buildAdminDeepLink(configWith({}), '/dashboard/events/e1');
    const inviteUrl = buildAdminAcceptInviteUrl(configWith({}), 'inv-1', 'tok-abc');
    expect(reportUrl).not.toContain('localhost');
    expect(inviteUrl).not.toContain('localhost');
    expect(reportUrl).toBe('https://admin.chisto.mk/dashboard/events/e1');
    expect(inviteUrl).toBe(
      'https://admin.chisto.mk/accept-invite?id=inv-1&token=tok-abc',
    );
  });

  it('honors ADMIN_APP_BASE_URL override', () => {
    const cfg = configWith({ ADMIN_APP_BASE_URL: 'https://staging-admin.example.test/' });
    expect(buildAdminDeepLink(cfg, 'dashboard/moderation/ugc?reportId=u1')).toBe(
      'https://staging-admin.example.test/dashboard/moderation/ugc?reportId=u1',
    );
    expect(buildAdminAcceptInviteUrl(cfg, 'inv-2', 'tok-xyz')).toBe(
      'https://staging-admin.example.test/accept-invite?id=inv-2&token=tok-xyz',
    );
  });

  it('allows localhost override for local development', () => {
    const cfg = configWith({ ADMIN_APP_BASE_URL: 'http://localhost:3001' });
    expect(buildAdminAcceptInviteUrl(cfg, 'inv-3', 'tok-dev')).toBe(
      'http://localhost:3001/accept-invite?id=inv-3&token=tok-dev',
    );
  });
});

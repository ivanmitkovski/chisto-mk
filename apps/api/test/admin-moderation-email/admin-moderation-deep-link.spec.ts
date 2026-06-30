/// <reference types="jest" />

import { ConfigService } from '@nestjs/config';
import {
  buildAdminDeepLink,
  resolveAdminAppBaseUrl,
} from '../../src/admin-moderation-email/util/admin-moderation-deep-link';

describe('admin-moderation-deep-link', () => {
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
    const url = buildAdminDeepLink(configWith({}), '/dashboard/events/e1');
    expect(url).not.toContain('localhost');
    expect(url).toBe('https://admin.chisto.mk/dashboard/events/e1');
  });

  it('honors ADMIN_APP_BASE_URL override', () => {
    const cfg = configWith({ ADMIN_APP_BASE_URL: 'https://staging-admin.example.test/' });
    expect(buildAdminDeepLink(cfg, 'dashboard/moderation/ugc?reportId=u1')).toBe(
      'https://staging-admin.example.test/dashboard/moderation/ugc?reportId=u1',
    );
  });
});

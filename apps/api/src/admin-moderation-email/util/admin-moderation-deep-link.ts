import { ConfigService } from '@nestjs/config';
import { DEFAULT_ADMIN_APP_BASE_URL } from '../../email/constants/email.constants';
import { normalizeHttpsBase } from '../../email/util/email-url.util';

export function resolveAdminAppBaseUrl(config: ConfigService): string {
  const fromEnv = normalizeHttpsBase(config.get<string>('ADMIN_APP_BASE_URL'));
  return fromEnv || DEFAULT_ADMIN_APP_BASE_URL;
}

export function buildAdminDeepLink(config: ConfigService, path: string): string {
  const base = resolveAdminAppBaseUrl(config);
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${base}${normalizedPath}`;
}

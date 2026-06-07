import type { ConfigService } from '@nestjs/config';
import { DEFAULT_ADMIN_APP_BASE_URL } from '../constants/email.constants';
import { normalizeHttpsBase } from './email-url.util';

type ConfigReader = Pick<ConfigService, 'get'> | { get(key: string): string | undefined };

/** Admin console origin for invite accept links and moderation email CTAs (no trailing slash). */
export function resolveAdminAppBaseUrl(config: ConfigReader): string {
  const fromEnv = normalizeHttpsBase(config.get('ADMIN_APP_BASE_URL'));
  return fromEnv || DEFAULT_ADMIN_APP_BASE_URL;
}

export function buildAdminDeepLink(config: ConfigReader, path: string): string {
  const base = resolveAdminAppBaseUrl(config);
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${base}${normalizedPath}`;
}

export function buildAdminAcceptInviteUrl(
  config: ConfigReader,
  inviteId: string,
  token: string,
): string {
  const url = new URL('/accept-invite', `${resolveAdminAppBaseUrl(config)}/`);
  url.searchParams.set('id', inviteId);
  url.searchParams.set('token', token);
  return url.toString();
}

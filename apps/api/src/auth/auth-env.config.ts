import type { ConfigService } from '@nestjs/config';

export const AUTH_ENV_RUNTIME = 'AUTH_ENV_RUNTIME' as const;

const REMEMBER_ME_SHORT_DAYS = 1;

export type AuthEnvRuntime = {
  saltRounds: number;
  accessTokenTtl: number;
  refreshTokenTtlDays: number;
  maxSessionsPerUser: number;
  shouldReturnDevCode: boolean;
};

export function loadAuthEnvRuntime(configService: ConfigService | null): AuthEnvRuntime {
  const cfg = (key: string): string | undefined =>
    configService?.get<string>(key)?.trim() ?? process.env[key]?.trim();
  const isProduction = cfg('NODE_ENV') === 'production';
  const smsProvider = cfg('SMS_PROVIDER')?.toLowerCase() ?? 'none';
  const shouldReturnDevCode = !isProduction && smsProvider !== 'twilio';
  const accessRaw = cfg('JWT_ACCESS_EXPIRES_IN');
  const accessTokenTtl = accessRaw ? Number(accessRaw) : 900;
  if (!Number.isFinite(accessTokenTtl) || accessTokenTtl < 60 || accessTokenTtl > 86400) {
    throw new Error(`JWT_ACCESS_EXPIRES_IN must be an integer between 60 and 86400 (got: ${accessRaw})`);
  }
  const refreshRaw = cfg('JWT_REFRESH_EXPIRES_DAYS');
  const refreshTokenTtlDays = refreshRaw ? Number(refreshRaw) : 7;
  if (!Number.isFinite(refreshTokenTtlDays) || refreshTokenTtlDays < 1 || refreshTokenTtlDays > 365) {
    throw new Error(`JWT_REFRESH_EXPIRES_DAYS must be an integer between 1 and 365 (got: ${refreshRaw})`);
  }
  const maxSessionsRaw = cfg('MAX_SESSIONS_PER_USER');
  const maxSessionsPerUser = maxSessionsRaw ? Number(maxSessionsRaw) : 5;
  if (!Number.isFinite(maxSessionsPerUser) || maxSessionsPerUser < 1 || maxSessionsPerUser > 100) {
    throw new Error(`MAX_SESSIONS_PER_USER must be an integer between 1 and 100 (got: ${maxSessionsRaw})`);
  }
  return {
    saltRounds: 12,
    accessTokenTtl,
    refreshTokenTtlDays,
    maxSessionsPerUser,
    shouldReturnDevCode,
  };
}

export { REMEMBER_ME_SHORT_DAYS };

import type { ConfigService } from '@nestjs/config';
import type { JwtService } from '@nestjs/jwt';
import type { User } from '../prisma-client';
import type { ReportsUploadService } from '../reports/reports-upload.service';
import type { AuthEnvRuntime } from './auth-env.config';
import { defaultJwtKid, resolveJwtSecretsFromEnv } from './jwt-secret.resolver';
import { resolveTermsVersionFromEnv, termsConsentPayload } from './terms-consent.util';
import type { AuthResponse } from './types/auth-response.type';

export async function buildAuthResponsePayload(
  user: User,
  sessionId: string,
  fullRefreshToken: string,
  deps: {
    jwtService: JwtService;
    reportsUploadService: ReportsUploadService;
    configService: ConfigService;
    env: AuthEnvRuntime;
  },
): Promise<AuthResponse> {
  const jwtKid = defaultJwtKid(resolveJwtSecretsFromEnv());
  const accessToken = deps.jwtService.sign(
    {
      sub: user.id,
      role: user.role,
      sid: sessionId,
    },
    {
      expiresIn: deps.env.accessTokenTtl,
      issuer: 'chisto-api',
      audience: 'chisto-api',
      header: { kid: jwtKid, alg: 'HS256' },
    },
  );

  const avatarUrl = await deps.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);
  const currentTermsVersion = resolveTermsVersionFromEnv(
    deps.configService.get<string>('TERMS_VERSION'),
  );
  const consent = termsConsentPayload(user, currentTermsVersion);

  return {
    accessToken,
    refreshToken: fullRefreshToken,
    user: {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role,
      status: user.status,
      isPhoneVerified: user.isPhoneVerified,
      pointsBalance: user.pointsBalance,
      avatarUrl,
      organizerCertifiedAt: user.organizerCertifiedAt?.toISOString() ?? null,
      ...consent,
    },
  };
}

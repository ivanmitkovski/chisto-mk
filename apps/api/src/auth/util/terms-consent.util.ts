import { BadRequestException } from '@nestjs/common';

export const DEFAULT_TERMS_VERSION = '1';

const MAX_TERMS_ACCEPTANCE_SKEW_MS = 5 * 60 * 1000;

export function resolveTermsVersionFromEnv(raw?: string): string {
  const v = raw?.trim();
  return v && v.length > 0 ? v : DEFAULT_TERMS_VERSION;
}

export type TermsConsentFields = {
  termsAcceptedAt: Date | null;
  termsVersion: string | null;
};

export function userHasCurrentTermsAcceptance(
  user: TermsConsentFields,
  currentVersion: string,
): boolean {
  return (
    user.termsAcceptedAt != null &&
    user.termsVersion != null &&
    user.termsVersion.trim() === currentVersion
  );
}

export function requiresTermsAcceptance(
  user: TermsConsentFields,
  currentVersion: string,
): boolean {
  return !userHasCurrentTermsAcceptance(user, currentVersion);
}

export function termsConsentPayload(
  user: TermsConsentFields,
  currentVersion: string,
): {
  termsAcceptedAt: string | null;
  termsVersion: string | null;
  requiresTermsAcceptance: boolean;
} {
  return {
    termsAcceptedAt: user.termsAcceptedAt?.toISOString() ?? null,
    termsVersion: user.termsVersion,
    requiresTermsAcceptance: requiresTermsAcceptance(user, currentVersion),
  };
}

export function assertRegisterTermsAcceptance(
  dto: { termsAcceptedAt: string; termsVersion: string },
  currentVersion: string,
): void {
  const version = dto.termsVersion.trim();
  if (version !== currentVersion) {
    throw new BadRequestException({
      code: 'TERMS_VERSION_MISMATCH',
      message: `termsVersion must be ${currentVersion}`,
    });
  }

  const acceptedAt = new Date(dto.termsAcceptedAt);
  if (Number.isNaN(acceptedAt.getTime())) {
    throw new BadRequestException({
      code: 'TERMS_ACCEPTANCE_INVALID',
      message: 'termsAcceptedAt must be a valid ISO-8601 timestamp',
    });
  }

  const now = Date.now();
  if (acceptedAt.getTime() > now + MAX_TERMS_ACCEPTANCE_SKEW_MS) {
    throw new BadRequestException({
      code: 'TERMS_ACCEPTANCE_INVALID',
      message: 'termsAcceptedAt cannot be in the future',
    });
  }
}

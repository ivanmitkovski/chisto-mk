type InviteErrorContext = 'validate' | 'begin-mfa' | 'accept' | 'credentials';

type InviteErrorTranslator = (key: string) => string;

const CONTEXT_DEFAULT_KEY: Record<InviteErrorContext, string> = {
  validate: 'validateDefault',
  'begin-mfa': 'beginMfaDefault',
  accept: 'acceptDefault',
  credentials: 'credentialsDefault',
};

const CODE_TO_KEY: Record<string, string> = {
  INVITE_LOCKED: 'locked',
  INVITE_REVOKED: 'revoked',
  INVITE_ALREADY_ACCEPTED: 'alreadyAccepted',
  INVITE_EXPIRED: 'expired',
  INVALID_INVITE: 'expired',
  INVITE_NOT_PENDING: 'notPending',
  INVALID_TOTP_CODE: 'invalidTotp',
  MFA_SETUP_REQUIRED: 'mfaRequired',
  EMAIL_ALREADY_REGISTERED: 'emailRegistered',
  PHONE_NUMBER_IN_USE: 'phoneInUse',
  TOO_MANY_REQUESTS: 'tooManyRequests',
  BAD_REQUEST: 'badRequest',
};

const SIGN_IN_REDIRECT_CODES = new Set([
  'INVITE_ALREADY_ACCEPTED',
  'INVITE_REVOKED',
  'EMAIL_ALREADY_REGISTERED',
]);

export function shouldOfferInviteSignIn(code: string | undefined): boolean {
  return code != null && SIGN_IN_REDIRECT_CODES.has(code);
}

export function mapInviteErrorMessage(
  code: string | undefined,
  context: InviteErrorContext,
  t: InviteErrorTranslator,
  fallback?: string,
): string {
  if (code === 'BAD_REQUEST') {
    return fallback ?? t(`errors.${CODE_TO_KEY.BAD_REQUEST}`);
  }

  if (code && CODE_TO_KEY[code]) {
    return t(`errors.${CODE_TO_KEY[code]}`);
  }

  return fallback ?? t(`errors.${CONTEXT_DEFAULT_KEY[context]}`);
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim() === '') {
    console.error(`Missing required environment variable: ${name}`);
    process.exit(1);
  }
  return value.trim();
}

function optionalEnv(name: string, defaultValue: string): string {
  const value = process.env[name];
  return (value === undefined || value.trim() === '') ? defaultValue : value.trim();
}

const MIN_JWT_SECRET_LENGTH = 32;

export function validateEnv(): void {
  requireEnv('DATABASE_URL');
  const jwtSecret = requireEnv('JWT_SECRET');
  const nodeEnv = optionalEnv('NODE_ENV', 'development');
  if ((nodeEnv === 'production' || nodeEnv === 'staging') && jwtSecret.length < MIN_JWT_SECRET_LENGTH) {
    console.error(
      `JWT_SECRET must be at least ${MIN_JWT_SECRET_LENGTH} characters in production/staging (current: ${jwtSecret.length})`,
    );
    process.exit(1);
  }
  if (nodeEnv === 'production' || nodeEnv === 'staging') {
    const cors = process.env.CORS_ORIGINS;
    if (!cors || cors.trim() === '') {
      console.error('CORS_ORIGINS is required when NODE_ENV is production or staging');
      process.exit(1);
    }
  }
  optionalEnv('PORT', '3000');
  optionalEnv('JWT_ACCESS_EXPIRES_IN', '900');
  optionalEnv('JWT_REFRESH_EXPIRES_DAYS', '7');
  optionalEnv('MAX_SESSIONS_PER_USER', '5');
  const smsProvider = (process.env.SMS_PROVIDER ?? 'none').toLowerCase();
  if (smsProvider === 'twilio') {
    requireEnv('TWILIO_ACCOUNT_SID');
    requireEnv('TWILIO_AUTH_TOKEN');
    const messagingSid = process.env.TWILIO_MESSAGING_SERVICE_SID?.trim();
    const fromNumber = process.env.TWILIO_PHONE_NUMBER?.trim();
    if (!messagingSid && !fromNumber) {
      console.error('TWILIO_MESSAGING_SERVICE_SID or TWILIO_PHONE_NUMBER is required when SMS_PROVIDER=twilio');
      process.exit(1);
    }
  }

  // SECURITY: When uploads are enabled in production, require explicit AWS credentials (no implicit instance roles in config drift).
  const bucket = process.env.S3_BUCKET_NAME?.trim();
  if (bucket && (nodeEnv === 'production' || nodeEnv === 'staging')) {
    requireEnv('AWS_ACCESS_KEY_ID');
    requireEnv('AWS_SECRET_ACCESS_KEY');
  }
}

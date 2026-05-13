import Joi from 'joi';

const MIN_JWT_SECRET_LENGTH = 32;

function requireEnv(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim() === '') {
    console.error(`Missing required environment variable: ${name}`);
    process.exit(1);
  }
  return value.trim();
}

export function validateEnv(): void {
  const schema = Joi.object({
    DATABASE_URL: Joi.string().trim().min(1).required(),
    JWT_SECRET: Joi.string().trim().min(1).required(),
    NODE_ENV: Joi.string()
      .trim()
      .valid('development', 'test', 'production', 'staging')
      .default('development'),
    CORS_ORIGINS: Joi.string().allow('').optional(),
    JWT_ACCESS_EXPIRES_IN: Joi.number().integer().min(60).max(86400).default(900),
    JWT_REFRESH_EXPIRES_DAYS: Joi.number().integer().min(1).max(365).default(30),
    MAX_SESSIONS_PER_USER: Joi.number().integer().min(1).max(100).default(5),
    SENTRY_DSN: Joi.string().trim().allow('').optional(),
    SENTRY_TRACES_SAMPLE_RATE: Joi.number().min(0).max(1).optional(),
  }).unknown(true);

  const { error, value } = schema.validate(process.env, { abortEarly: false, allowUnknown: true });
  if (error) {
    for (const detail of error.details) {
      console.error(detail.message);
    }
    process.exit(1);
  }

  for (const key of ['JWT_ACCESS_EXPIRES_IN', 'JWT_REFRESH_EXPIRES_DAYS', 'MAX_SESSIONS_PER_USER'] as const) {
    process.env[key] = String(value[key]);
  }

  const nodeEnv = (process.env.NODE_ENV ?? 'development').trim() || 'development';
  const jwtSecret = process.env.JWT_SECRET?.trim() ?? '';
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

    const accessTtl = Number(process.env.JWT_ACCESS_EXPIRES_IN ?? 900);
    if (!Number.isFinite(accessTtl) || accessTtl < 60 || accessTtl > 86400) {
      console.error('JWT_ACCESS_EXPIRES_IN must be a finite integer from 60 to 86400 (seconds)');
      process.exit(1);
    }
    const refreshDays = Number(process.env.JWT_REFRESH_EXPIRES_DAYS ?? 30);
    if (!Number.isFinite(refreshDays) || refreshDays < 1 || refreshDays > 365) {
      console.error('JWT_REFRESH_EXPIRES_DAYS must be a finite integer from 1 to 365');
      process.exit(1);
    }
    const maxSessions = Number(process.env.MAX_SESSIONS_PER_USER ?? 5);
    if (!Number.isFinite(maxSessions) || maxSessions < 1 || maxSessions > 100) {
      console.error('MAX_SESSIONS_PER_USER must be a finite integer from 1 to 100');
      process.exit(1);
    }

    const sentryDsn = process.env.SENTRY_DSN?.trim();
    if (sentryDsn) {
      const rateRaw = process.env.SENTRY_TRACES_SAMPLE_RATE?.trim();
      if (rateRaw === undefined || rateRaw === '') {
        console.error(
          'SENTRY_TRACES_SAMPLE_RATE is required when SENTRY_DSN is set (use a number from 0 to 1)',
        );
        process.exit(1);
      }
      const rate = Number(rateRaw);
      if (!Number.isFinite(rate) || rate < 0 || rate > 1) {
        console.error('SENTRY_TRACES_SAMPLE_RATE must be a finite number from 0 to 1');
        process.exit(1);
      }
    }
  }

  const smsProvider = (process.env.SMS_PROVIDER ?? 'none').toLowerCase();
  if (smsProvider === 'twilio') {
    requireEnv('TWILIO_ACCOUNT_SID');
    requireEnv('TWILIO_AUTH_TOKEN');
    const messagingSid = process.env.TWILIO_MESSAGING_SERVICE_SID?.trim();
    const fromNumber = process.env.TWILIO_PHONE_NUMBER?.trim();
    const alphaSender = process.env.TWILIO_ALPHANUMERIC_SENDER?.trim();
    if (!messagingSid && !fromNumber && !alphaSender) {
      console.error(
        'When SMS_PROVIDER=twilio, set TWILIO_MESSAGING_SERVICE_SID and/or TWILIO_PHONE_NUMBER and/or TWILIO_ALPHANUMERIC_SENDER (at least one sender path)',
      );
      process.exit(1);
    }
  }

  const bucket = process.env.S3_BUCKET_NAME?.trim();
  if (bucket && (nodeEnv === 'production' || nodeEnv === 'staging')) {
    const hasStaticKeys =
      Boolean(process.env.AWS_ACCESS_KEY_ID?.trim()) &&
      Boolean(process.env.AWS_SECRET_ACCESS_KEY?.trim());
    const hasEcsTaskRole = Boolean(process.env.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI?.trim());
    const hasWebIdentity = Boolean(process.env.AWS_WEB_IDENTITY_TOKEN_FILE?.trim());
    if (!hasStaticKeys && !hasEcsTaskRole && !hasWebIdentity) {
      console.error(
        'When S3_BUCKET_NAME is set in production/staging, configure AWS credentials: set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, or attach an IAM task role to this container (ECS), or use IRSA (EKS).',
      );
      process.exit(1);
    }
  }
}

try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  require('dotenv').config();
} catch {
  /* optional in CI where env is injected */
}
process.env.NODE_ENV = 'test';
const localDb =
  process.env.DATABASE_URL?.includes('127.0.0.1') ||
  process.env.DATABASE_URL?.includes('localhost');
if (!localDb) {
  process.env.DATABASE_URL = 'postgresql://chisto:chisto@127.0.0.1:5432/chisto';
}
if (!process.env.DATABASE_URL?.includes('connection_limit=')) {
  process.env.DATABASE_URL += process.env.DATABASE_URL.includes('?')
    ? '&connection_limit=3'
    : '?connection_limit=3';
}
process.env.SMS_PROVIDER = 'none';
process.env.OTP_DEV_RETURN_CODE = 'true';
process.env.REFRESH_TOKEN_ROTATION_GRACE_SECONDS = '0';
process.env.EMAIL_ENABLED = 'true';
process.env.POSTMARK_SERVER_TOKEN = 'ci-placeholder-not-used-in-e2e';

/// <reference types="jest" />

import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';

describe('loadAuthEnvRuntime', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('defaults refreshTokenStandardDays to 7 and jwtClockToleranceSeconds to 30', () => {
    delete process.env.JWT_REFRESH_STANDARD_DAYS;
    delete process.env.JWT_CLOCK_TOLERANCE_SECONDS;
    const env = loadAuthEnvRuntime(null);
    expect(env.refreshTokenStandardDays).toBe(7);
    expect(env.jwtClockToleranceSeconds).toBe(30);
  });

  it('defaults remember-me refresh TTL, rotation grace, and max sessions', () => {
    delete process.env.JWT_REFRESH_EXPIRES_DAYS;
    delete process.env.REFRESH_TOKEN_ROTATION_GRACE_SECONDS;
    delete process.env.MAX_SESSIONS_PER_USER;
    const env = loadAuthEnvRuntime(null);
    expect(env.refreshTokenTtlDays).toBe(90);
    expect(env.refreshTokenRotationGraceSeconds).toBe(120);
    expect(env.maxSessionsPerUser).toBe(20);
  });

  it('reads JWT_REFRESH_STANDARD_DAYS and JWT_CLOCK_TOLERANCE_SECONDS from env', () => {
    process.env.JWT_REFRESH_STANDARD_DAYS = '14';
    process.env.JWT_CLOCK_TOLERANCE_SECONDS = '45';
    const env = loadAuthEnvRuntime(null);
    expect(env.refreshTokenStandardDays).toBe(14);
    expect(env.jwtClockToleranceSeconds).toBe(45);
  });
});

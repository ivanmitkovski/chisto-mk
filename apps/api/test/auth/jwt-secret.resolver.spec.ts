/// <reference types="jest" />

import {
  defaultJwtKid,
  resolveJwtSecretsFromEnv,
  secretForKid,
} from '../../src/auth/util/jwt-secret.resolver';

describe('resolveJwtSecretsFromEnv', () => {
  it('returns current secret only when JWT_SECRET_PREVIOUS is unset', () => {
    const entries = resolveJwtSecretsFromEnv({
      JWT_SECRET: 'current-secret',
      JWT_KID: 'kid-1',
    });
    expect(entries).toEqual([{ kid: 'kid-1', secret: 'current-secret' }]);
    expect(defaultJwtKid(entries)).toBe('kid-1');
    expect(secretForKid(undefined, entries)).toBe('current-secret');
  });

  it('includes previous secret for rotation when distinct', () => {
    const entries = resolveJwtSecretsFromEnv({
      JWT_SECRET: 'new-secret',
      JWT_SECRET_PREVIOUS: 'old-secret',
      JWT_KID: 'new',
      JWT_KID_PREVIOUS: 'old',
    });
    expect(entries).toEqual([
      { kid: 'new', secret: 'new-secret' },
      { kid: 'old', secret: 'old-secret' },
    ]);
    expect(secretForKid('old', entries)).toBe('old-secret');
    expect(secretForKid('new', entries)).toBe('new-secret');
  });

  it('skips duplicate previous secret', () => {
    const entries = resolveJwtSecretsFromEnv({
      JWT_SECRET: 'same-secret',
      JWT_SECRET_PREVIOUS: 'same-secret',
    });
    expect(entries).toHaveLength(1);
  });
});

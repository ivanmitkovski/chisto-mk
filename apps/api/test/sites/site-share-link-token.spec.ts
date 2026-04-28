import {
  SITE_SHARE_LINK_TTL_SEC,
  signSiteShareLinkToken,
  verifySiteShareLinkToken,
} from '../../src/sites/site-share-link-token';

describe('site-share-link-token', () => {
  const secret = Buffer.from('unit_test_site_share_token_secret_24', 'utf8');

  it('signs and verifies a valid token', () => {
    const now = Math.floor(Date.now() / 1000);
    const token = signSiteShareLinkToken(secret, {
      s: 'site_1',
      c: 'cid_1',
      ch: 'native',
      iat: now,
      exp: now + SITE_SHARE_LINK_TTL_SEC,
    });
    const verified = verifySiteShareLinkToken(secret, token, now + 10);
    expect(verified.ok).toBe(true);
    if (verified.ok) {
      expect(verified.claims.s).toBe('site_1');
      expect(verified.claims.c).toBe('cid_1');
      expect(verified.claims.ch).toBe('native');
    }
  });

  it('rejects expired token', () => {
    const now = Math.floor(Date.now() / 1000);
    const token = signSiteShareLinkToken(secret, {
      s: 'site_1',
      c: 'cid_1',
      ch: 'link',
      iat: now - 20,
      exp: now - 10,
    });
    const verified = verifySiteShareLinkToken(secret, token, now);
    expect(verified).toEqual({ ok: false, reason: 'EXPIRED' });
  });

  it('rejects tampered token', () => {
    const now = Math.floor(Date.now() / 1000);
    const token = signSiteShareLinkToken(secret, {
      s: 'site_1',
      c: 'cid_1',
      ch: 'x',
      iat: now,
      exp: now + 60,
    });
    const tampered = `${token}x`;
    const verified = verifySiteShareLinkToken(secret, tampered, now);
    expect(verified).toEqual({ ok: false, reason: 'INVALID_SIGNATURE' });
  });
});

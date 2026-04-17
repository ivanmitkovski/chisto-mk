import {
  CHECK_IN_QR_TTL_SEC,
  signCheckInQrToken,
  verifyCheckInQrToken,
} from '../../src/events/check-in-qr-token';

describe('check-in-qr-token', () => {
  const secret = Buffer.from('test_secret_at_least_24_chars_x', 'utf8');

  it('round-trips and verifies claims', () => {
    const nowSec = 1_700_000_000;
    const claims = {
      e: 'evt_1',
      s: 'sess_1',
      j: 'jti_1',
      iat: nowSec,
      exp: nowSec + CHECK_IN_QR_TTL_SEC,
    };
    const token = signCheckInQrToken(secret, claims);
    const v = verifyCheckInQrToken(secret, token, nowSec);
    expect(v.ok).toBe(true);
    if (v.ok) {
      expect(v.claims).toEqual(claims);
    }
  });

  it('rejects tampered signature', () => {
    const nowSec = 1_700_000_000;
    const token = signCheckInQrToken(secret, {
      e: 'evt_1',
      s: 'sess_1',
      j: 'jti_1',
      iat: nowSec,
      exp: nowSec + CHECK_IN_QR_TTL_SEC,
    });
    const tampered = `${token.slice(0, -4)}xxxx`;
    const v = verifyCheckInQrToken(secret, tampered, nowSec);
    expect(v.ok).toBe(false);
    if (!v.ok) {
      expect(v.reason).toBe('INVALID_SIGNATURE');
    }
  });

  it('rejects expired tokens', () => {
    const nowSec = 1_700_000_000;
    const token = signCheckInQrToken(secret, {
      e: 'evt_1',
      s: 'sess_1',
      j: 'jti_1',
      iat: nowSec,
      exp: nowSec + 10,
    });
    const v = verifyCheckInQrToken(secret, token, nowSec + 20);
    expect(v.ok).toBe(false);
    if (!v.ok) {
      expect(v.reason).toBe('EXPIRED');
    }
  });

  it('accepts token at exp boundary (clock alignment with server second)', () => {
    const nowSec = 1_700_000_000;
    const exp = nowSec + 30;
    const token = signCheckInQrToken(secret, {
      e: 'evt_1',
      s: 'sess_1',
      j: 'jti_1',
      iat: nowSec,
      exp,
    });
    const v = verifyCheckInQrToken(secret, token, exp);
    expect(v.ok).toBe(true);
  });
});

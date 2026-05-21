/// <reference types="jest" />

import { isValidRecipientEmail } from '../../src/email/email-recipient';

describe('isValidRecipientEmail', () => {
  it('accepts typical addresses', () => {
    expect(isValidRecipientEmail('user@example.com')).toBe(true);
    expect(isValidRecipientEmail('  a@b.co  ')).toBe(true);
    expect(isValidRecipientEmail('first.last+tag@mail.example.org')).toBe(true);
  });

  it('rejects invalid values', () => {
    expect(isValidRecipientEmail('')).toBe(false);
    expect(isValidRecipientEmail('nope')).toBe(false);
    expect(isValidRecipientEmail('@nodomain')).toBe(false);
    expect(isValidRecipientEmail('spaces in@here.com')).toBe(false);
  });
});

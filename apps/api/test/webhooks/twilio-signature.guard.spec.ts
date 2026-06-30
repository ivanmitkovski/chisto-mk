import { UnauthorizedException } from '@nestjs/common';
import { TwilioSignatureGuard } from '../../src/webhooks/guards/twilio-signature.guard';
import twilio from 'twilio';

describe('TwilioSignatureGuard', () => {
  const authToken = 'test_token';
  const baseUrl = 'https://api.example.com';

  const config = {
    get: jest.fn((key: string) => {
      if (key === 'TWILIO_AUTH_TOKEN') return authToken;
      if (key === 'TWILIO_WEBHOOK_BASE_URL') return baseUrl;
      return undefined;
    }),
  };

  function context(body: Record<string, string>, signature?: string) {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          headers:
            signature != null ? { 'x-twilio-signature': signature } : {},
          body,
        }),
      }),
    } as never;
  }

  it('accepts valid signature', () => {
    const params = { MessageSid: 'SM1', MessageStatus: 'delivered' };
    const url = `${baseUrl}/v1/webhooks/twilio/status`;
    const signature = twilio.getExpectedTwilioSignature(authToken, url, params);
    const guard = new TwilioSignatureGuard(config as never);
    expect(guard.canActivate(context(params, signature))).toBe(true);
  });

  it('rejects missing signature', () => {
    const guard = new TwilioSignatureGuard(config as never);
    expect(() => guard.canActivate(context({ MessageSid: 'SM1' }))).toThrow(
      UnauthorizedException,
    );
  });
});

import { UnauthorizedException } from '@nestjs/common';
import { PostmarkWebhookBasicAuthGuard } from '../../src/webhooks/guards/postmark-webhook-basic-auth.guard';

describe('PostmarkWebhookBasicAuthGuard', () => {
  const config = {
    get: jest.fn((key: string) => {
      if (key === 'POSTMARK_WEBHOOK_BASIC_USER') return 'user';
      if (key === 'POSTMARK_WEBHOOK_BASIC_PASS') return 'secret';
      return undefined;
    }),
  };

  function contextWithAuth(header?: string) {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          headers: header != null ? { authorization: header } : {},
        }),
      }),
    } as never;
  }

  it('accepts valid Basic credentials', () => {
    const token = Buffer.from('user:secret').toString('base64');
    const guard = new PostmarkWebhookBasicAuthGuard(config as never);
    expect(guard.canActivate(contextWithAuth(`Basic ${token}`))).toBe(true);
  });

  it('rejects missing auth', () => {
    const guard = new PostmarkWebhookBasicAuthGuard(config as never);
    expect(() => guard.canActivate(contextWithAuth())).toThrow(UnauthorizedException);
  });

  it('rejects wrong password', () => {
    const token = Buffer.from('user:wrong').toString('base64');
    const guard = new PostmarkWebhookBasicAuthGuard(config as never);
    expect(() => guard.canActivate(contextWithAuth(`Basic ${token}`))).toThrow(
      UnauthorizedException,
    );
  });
});

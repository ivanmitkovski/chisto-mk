/// <reference types="jest" />

import * as jwt from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';
import { NotificationType } from '../../src/prisma-client';
import { EmailUnsubscribeTokenService } from '../../src/email/services/email-unsubscribe-token.service';

describe('EmailUnsubscribeTokenService', () => {
  const secret = 'test-jwt-secret-for-email-unsubscribe-32';

  it('signs and verifies round-trip', () => {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'JWT_SECRET') return secret;
        return undefined;
      }),
    } as unknown as ConfigService;

    const svc = new EmailUnsubscribeTokenService(config);
    const token = svc.sign('user-abc', NotificationType.COMMENT);
    const payload = svc.verify(token);
    expect(payload.sub).toBe('user-abc');
    expect(payload.notificationType).toBe(NotificationType.COMMENT);
    expect(payload.typ).toBe('email_unsub');
  });

  it('defaults notification type to ALL when missing in token', () => {
    const token = jwt.sign({ sub: 'u1', typ: 'email_unsub', v: 1 }, secret, { expiresIn: '1h' });
    const config = {
      get: jest.fn((key: string) => (key === 'JWT_SECRET' ? secret : undefined)),
    } as unknown as ConfigService;
    const svc = new EmailUnsubscribeTokenService(config);
    const payload = svc.verify(token);
    expect(payload.notificationType).toBe('ALL');
  });
});

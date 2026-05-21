import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { NotificationType } from '../prisma-client';
import type { EmailUnsubscribeJwtPayload } from './email.types';

@Injectable()
export class EmailUnsubscribeTokenService {
  constructor(private readonly config: ConfigService) {}

  sign(userId: string, notificationType: NotificationType | 'ALL'): string {
    const secret = this.requireJwtSecret('JWT_SECRET is required for email unsubscribe tokens');
    const payload: EmailUnsubscribeJwtPayload = {
      sub: userId,
      typ: 'email_unsub',
      notificationType,
      v: 1,
    };
    return jwt.sign(payload, secret, { expiresIn: '180d' });
  }

  verify(token: string): EmailUnsubscribeJwtPayload {
    const secret = this.requireJwtSecret('JWT_SECRET is not configured');
    const decoded = jwt.verify(token, secret) as jwt.JwtPayload & Partial<EmailUnsubscribeJwtPayload>;
    if (decoded.typ !== 'email_unsub' || typeof decoded.sub !== 'string') {
      throw new Error('Invalid unsubscribe token');
    }
    return {
      sub: decoded.sub,
      typ: 'email_unsub',
      notificationType: (decoded.notificationType as EmailUnsubscribeJwtPayload['notificationType']) ?? 'ALL',
      v: 1,
    };
  }

  private requireJwtSecret(missingMessage: string): string {
    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error(missingMessage);
    }
    return secret;
  }
}

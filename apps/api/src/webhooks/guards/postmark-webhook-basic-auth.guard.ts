import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { timingSafeEqual } from 'node:crypto';
import type { Request } from 'express';

@Injectable()
export class PostmarkWebhookBasicAuthGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers.authorization;
    if (header == null || !header.startsWith('Basic ')) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    const expectedUser = this.config.get<string>('POSTMARK_WEBHOOK_BASIC_USER')?.trim() ?? '';
    const expectedPass = this.config.get<string>('POSTMARK_WEBHOOK_BASIC_PASS')?.trim() ?? '';
    if (expectedUser.length === 0 || expectedPass.length === 0) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    let decoded: string;
    try {
      decoded = Buffer.from(header.slice('Basic '.length), 'base64').toString('utf8');
    } catch {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    const colon = decoded.indexOf(':');
    const user = colon >= 0 ? decoded.slice(0, colon) : decoded;
    const pass = colon >= 0 ? decoded.slice(colon + 1) : '';

    if (
      !safeEqual(user, expectedUser) ||
      !safeEqual(pass, expectedPass)
    ) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    return true;
  }
}

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'utf8');
  const bufB = Buffer.from(b, 'utf8');
  if (bufA.length !== bufB.length) {
    return false;
  }
  return timingSafeEqual(bufA, bufB);
}

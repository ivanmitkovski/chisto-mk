import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'node:crypto';
import type { Request } from 'express';
import { PostmarkWebhookBasicAuthGuard } from './postmark-webhook-basic-auth.guard';

@Injectable()
export class PostmarkWebhookSignatureGuard implements CanActivate {
  constructor(
    private readonly config: ConfigService,
    private readonly basicAuthFallback: PostmarkWebhookBasicAuthGuard,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const secret = this.config.get<string>('POSTMARK_WEBHOOK_SECRET')?.trim();
    if (!secret) {
      return this.basicAuthFallback.canActivate(context);
    }

    const req = context.switchToHttp().getRequest<Request & { rawBody?: Buffer }>();
    const signatureHeader = req.headers['x-postmark-signature'];
    const signature = Array.isArray(signatureHeader) ? signatureHeader[0] : signatureHeader;
    if (!signature?.trim()) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
    }

    const raw =
      req.rawBody ??
      (typeof req.body === 'string'
        ? Buffer.from(req.body)
        : Buffer.from(JSON.stringify(req.body ?? {})));
    const expected = createHmac('sha256', secret).update(raw).digest('base64');
    const a = Buffer.from(expected, 'utf8');
    const b = Buffer.from(signature.trim(), 'utf8');
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
    }
    return true;
  }
}

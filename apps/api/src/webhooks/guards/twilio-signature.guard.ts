import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';
import twilio from 'twilio';

@Injectable()
export class TwilioSignatureGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request>();
    const rawSignature = req.headers['x-twilio-signature'];
    const signature = Array.isArray(rawSignature) ? rawSignature[0] : rawSignature;
    if (signature == null || signature.trim() === '') {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    const authToken = this.config.get<string>('TWILIO_AUTH_TOKEN')?.trim();
    const baseUrl = this.config.get<string>('TWILIO_WEBHOOK_BASE_URL')?.trim();
    if (!authToken || !baseUrl) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    const normalizedBase = baseUrl.replace(/\/+$/, '');
    const url = `${normalizedBase}/webhooks/twilio/status`;
    const body = req.body;
    if (body == null || typeof body !== 'object' || Array.isArray(body)) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    const params: Record<string, string> = {};
    for (const [key, value] of Object.entries(body as Record<string, unknown>)) {
      if (value === undefined || value === null) {
        continue;
      }
      params[key] = String(value);
    }

    const valid = twilio.validateRequest(authToken, signature, url, params);
    if (!valid) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid request',
      });
    }

    return true;
  }
}

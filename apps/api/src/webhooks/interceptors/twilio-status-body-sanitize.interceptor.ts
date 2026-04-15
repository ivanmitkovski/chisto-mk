import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request } from 'express';
import { Observable } from 'rxjs';

const ALLOWED_KEYS = new Set<string>([
  'MessageSid',
  'MessageStatus',
  'To',
  'From',
  'ErrorCode',
  'ErrorMessage',
]);

/**
 * Twilio sends many extra form fields. The global {@link ValidationPipe} uses
 * `forbidNonWhitelisted: true`, so we keep only DTO-mapped keys before validation runs.
 */
@Injectable()
export class TwilioStatusBodySanitizeInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request>();
    const raw = req.body;
    if (raw != null && typeof raw === 'object' && !Array.isArray(raw)) {
      const nextBody: Record<string, unknown> = {};
      for (const key of ALLOWED_KEYS) {
        if (Object.prototype.hasOwnProperty.call(raw, key)) {
          nextBody[key] = (raw as Record<string, unknown>)[key];
        }
      }
      req.body = nextBody;
    }
    return next.handle();
  }
}

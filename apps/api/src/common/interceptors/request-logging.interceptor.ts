import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Observable, tap } from 'rxjs';
import { ObservabilityStore } from '../../observability/observability.store';

@Injectable()
export class RequestLoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('RequestLog');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<
      { method?: string; url?: string; headers?: Record<string, string>; requestId?: string }
    >();
    const res = http.getResponse<{ statusCode: number; setHeader: (name: string, value: string) => void }>();
    const startedAt = Date.now();
    const requestId = req.headers?.['x-request-id'] || randomUUID();
    req.requestId = requestId;
    res.setHeader('x-request-id', requestId);

    return next.handle().pipe(
      tap({
        next: () => {
          const durationMs = Date.now() - startedAt;
          const statusCode = res.statusCode ?? 200;
          ObservabilityStore.recordRequest(durationMs, statusCode);
          this.logger.log(
            JSON.stringify({
              requestId,
              method: req.method ?? 'UNKNOWN',
              route: req.url ?? 'unknown',
              statusCode,
              durationMs,
            }),
          );
        },
        error: () => {
          const durationMs = Date.now() - startedAt;
          const statusCode = res.statusCode ?? 500;
          ObservabilityStore.recordRequest(durationMs, statusCode);
        },
      }),
    );
  }
}

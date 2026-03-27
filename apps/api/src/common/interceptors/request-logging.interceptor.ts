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

/** Paths matched after stripping query string; trailing slashes normalized. */
const DEFAULT_SKIP_LOG_PATHS = new Set<string>(['/health', '/metrics']);

@Injectable()
export class RequestLoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('RequestLog');

  /** When true, log and record metrics for every request including probes. */
  private readonly logAllRequests =
    process.env.REQUEST_LOG_ALL_REQUESTS === 'true';

  private readonly skipPaths: Set<string> = (() => {
    const raw = process.env.REQUEST_LOG_SKIP_PATHS?.trim();
    if (!raw) {
      return DEFAULT_SKIP_LOG_PATHS;
    }
    const paths = new Set<string>();
    for (const part of raw.split(',')) {
      const p = part.trim();
      if (p) {
        paths.add(RequestLoggingInterceptor.normalizePath(p));
      }
    }
    return paths;
  })();

  private static normalizePath(urlOrPath: string): string {
    const withoutQuery = urlOrPath.split('?')[0] ?? '/';
    if (withoutQuery.length > 1 && withoutQuery.endsWith('/')) {
      return withoutQuery.slice(0, -1);
    }
    return withoutQuery || '/';
  }

  private shouldSkipLogging(url?: string): boolean {
    if (this.logAllRequests) {
      return false;
    }
    const path = RequestLoggingInterceptor.normalizePath(url ?? '/');
    return this.skipPaths.has(path);
  }

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

    if (this.shouldSkipLogging(req.url)) {
      return next.handle();
    }

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

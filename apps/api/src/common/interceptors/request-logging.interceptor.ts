import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Observable, finalize } from 'rxjs';
import { trace } from '@opentelemetry/api';
import { getInboundTraceparent } from '../logging/http-request-trace';
import {
  loadMetricsSkipPaths,
  normalizeHttpPath,
  shouldSkipMetricsForPath,
} from '../logging/metrics-skip-paths';
import { ObservabilityStore } from '../../observability/observability.store';

@Injectable()
export class RequestLoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('RequestLog');

  private readonly logAllRequests =
    process.env.REQUEST_LOG_ALL_REQUESTS === 'true';

  private readonly skipPaths = loadMetricsSkipPaths();

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }
    const http = context.switchToHttp();
    const req = http.getRequest<
      { method?: string; url?: string; headers?: Record<string, string>; requestId?: string }
    >();
    const res = http.getResponse<{ statusCode: number; setHeader: (name: string, value: string) => void }>();
    const startedAt = Date.now();
    const requestId = req.headers?.['x-request-id'] || randomUUID();
    req.requestId = requestId;
    res.setHeader('x-request-id', requestId);

    const skipLogging = shouldSkipMetricsForPath(req.url, this.logAllRequests, this.skipPaths);

    const traceparent = getInboundTraceparent() ?? null;
    const fromHeader = traceparent?.split('-')[1] ?? null;
    const activeSpan = trace.getActiveSpan();
    const fromOtel =
      activeSpan != null && activeSpan.spanContext().traceId
        ? activeSpan.spanContext().traceId
        : null;
    const traceId = fromHeader ?? fromOtel ?? null;

    return next.handle().pipe(
      finalize(() => {
        if (skipLogging) {
          return;
        }
        const durationMs = Date.now() - startedAt;
        const statusCode = res.statusCode ?? 200;
        ObservabilityStore.recordRequest(durationMs, statusCode);
        const level = statusCode >= 500 ? 'error' : statusCode >= 400 ? 'warn' : 'log';
        const payload = {
          msg: 'http_request',
          requestId,
          traceId,
          traceparent,
          method: req.method ?? 'UNKNOWN',
          route: normalizeHttpPath(req.url ?? '/'),
          statusCode,
          durationMs,
        };
        if (level === 'error') {
          this.logger.error(payload);
        } else if (level === 'warn') {
          this.logger.warn(payload);
        } else {
          this.logger.log(payload);
        }
      }),
    );
  }
}

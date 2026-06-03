import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, finalize } from 'rxjs';
import type { Request, Response } from 'express';
import {
  httpClientErrorsTotal,
  httpRequestDurationMs,
  httpRequestsFailedTotal,
  httpRequestsTotal,
  normalizeRouteForMetrics,
} from './prom-registry';
import {
  loadMetricsSkipPaths,
  shouldSkipMetricsForPath,
} from '../../common/logging/metrics-skip-paths';

@Injectable()
export class RequestMetricsInterceptor implements NestInterceptor {
  private readonly logAllRequests =
    process.env.REQUEST_LOG_ALL_REQUESTS === 'true';

  private readonly skipPaths = loadMetricsSkipPaths();

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }
    const req = context.switchToHttp().getRequest<Request>();
    const res = context.switchToHttp().getResponse<Response>();
    const started = Date.now();
    const method = req.method;
    const route = normalizeRouteForMetrics(req.originalUrl ?? req.url ?? '/');
    const skip = shouldSkipMetricsForPath(
      req.originalUrl ?? req.url,
      this.logAllRequests,
      this.skipPaths,
    );

    return next.handle().pipe(
      finalize(() => {
        if (skip) {
          return;
        }
        this.record(method, route, res.statusCode || 200, started);
      }),
    );
  }

  private record(method: string, route: string, status: number, started: number): void {
    const labels = { method, route, status: String(status) };
    httpRequestsTotal.inc(labels);
    httpRequestDurationMs.observe({ method, route, status: String(status) }, Date.now() - started);
    if (status >= 500) {
      httpRequestsFailedTotal.inc({ method, route });
    } else if (status >= 400) {
      httpClientErrorsTotal.inc({ method, route, status: String(status) });
    }
  }
}

import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import type { Request, Response } from 'express';
import {
  httpRequestDurationMs,
  httpRequestsFailedTotal,
  httpRequestsTotal,
  normalizeRouteForMetrics,
} from './prom-registry';

@Injectable()
export class RequestMetricsInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }
    const req = context.switchToHttp().getRequest<Request>();
    const res = context.switchToHttp().getResponse<Response>();
    const started = Date.now();
    const method = req.method;
    const route = normalizeRouteForMetrics(req.originalUrl ?? req.url ?? '/');

    return next.handle().pipe(
      tap({
        next: () => this.record(method, route, res.statusCode || 200, started),
        error: () => this.record(method, route, res.statusCode || 500, started),
      }),
    );
  }

  private record(method: string, route: string, status: number, started: number): void {
    const labels = { method, route, status: String(status) };
    httpRequestsTotal.inc(labels);
    httpRequestDurationMs.observe({ method, route, status: String(status) }, Date.now() - started);
    if (status >= 500) {
      httpRequestsFailedTotal.inc({ method, route });
    }
  }
}

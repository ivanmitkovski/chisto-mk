import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { SpanKind, SpanStatusCode, type Span, trace } from '@opentelemetry/api';
import type { Request, Response } from 'express';
import { randomBytes } from 'node:crypto';
import { Observable, tap } from 'rxjs';

const MAP_MODE_SEGMENTS: Record<string, string> = {
  sites: 'map.sites',
  clusters: 'map.clusters',
  heatmap: 'map.heatmap',
  sse: 'map.sse',
  mvt: 'map.mvt',
};

function deriveSpanName(path: string): string {
  const segments = path.replace(/^\/+/, '').split('/');
  for (const seg of segments) {
    const mapped = MAP_MODE_SEGMENTS[seg];
    if (mapped) return mapped;
  }
  return 'map.request';
}

function extractZoomBucket(query: Record<string, unknown>): string | undefined {
  const raw = query?.zoom ?? query?.z;
  if (raw === undefined || raw === null) return undefined;
  const zoom = Number(raw);
  if (Number.isNaN(zoom)) return undefined;
  if (zoom <= 8) return 'country';
  if (zoom <= 12) return 'region';
  if (zoom <= 15) return 'city';
  return 'street';
}

@Injectable()
export class MapHttpTracingInterceptor implements NestInterceptor {
  private static readonly logger = new Logger(MapHttpTracingInterceptor.name);
  private readonly tracer = trace.getTracer('chisto-map', '1.0.0');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<Request>();
    const res = http.getResponse<Response>();
    const started = Date.now();

    const route = (req.route?.path as string | undefined) ?? req.path;
    const cleanPath = req.originalUrl?.split('?')[0] ?? req.url;
    const spanName = deriveSpanName(cleanPath);
    const mapMode = spanName.split('.')[1] ?? 'unknown';

    const span: Span = this.tracer.startSpan(spanName, { kind: SpanKind.SERVER });
    span.setAttribute('http.method', req.method);
    span.setAttribute('http.route', route);
    span.setAttribute('map.mode', mapMode);

    const zoomBucket = extractZoomBucket(req.query as Record<string, unknown>);
    if (zoomBucket) {
      span.setAttribute('map.zoom_bucket', zoomBucket);
    }

    const spanContext = span.spanContext();
    const hasRealTrace =
      spanContext.traceId !== '00000000000000000000000000000000' &&
      spanContext.spanId !== '0000000000000000';

    const traceId = hasRealTrace ? spanContext.traceId : randomBytes(16).toString('hex');
    const spanId = hasRealTrace ? spanContext.spanId : randomBytes(8).toString('hex');
    const traceFlags = hasRealTrace ? spanContext.traceFlags.toString(16).padStart(2, '0') : '01';
    const traceparent = `00-${traceId}-${spanId}-${traceFlags}`;

    res.setHeader('traceparent', traceparent);

    const logSpans = process.env.MAP_OTEL_LOG_SPANS === 'true';

    return next.handle().pipe(
      tap({
        error: (err: Error) => {
          span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
          span.recordException(err);
          span.setAttribute('http.status_code', res.statusCode || 500);
          span.end();

          if (logSpans) {
            MapHttpTracingInterceptor.logger.log({
              msg: 'map_span',
              traceparent,
              method: req.method,
              path: cleanPath,
              mapMode,
              statusCode: res.statusCode || 500,
              durationMs: Date.now() - started,
              error: err.message,
            });
          }
        },
        finalize: () => {
          if (!span.isRecording()) return;

          span.setAttribute('http.status_code', res.statusCode);
          span.setStatus({ code: SpanStatusCode.OK });
          span.end();

          if (logSpans) {
            MapHttpTracingInterceptor.logger.log({
              msg: 'map_span',
              traceparent,
              method: req.method,
              path: cleanPath,
              mapMode,
              statusCode: res.statusCode,
              durationMs: Date.now() - started,
            });
          }
        },
      }),
    );
  }
}

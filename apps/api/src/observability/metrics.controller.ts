import { Controller, Get, Header } from '@nestjs/common';
import { ObservabilityStore } from './observability.store';

@Controller('metrics')
export class MetricsController {
  @Get()
  @Header('Content-Type', 'text/plain; version=0.0.4')
  metrics(): string {
    const s = ObservabilityStore.snapshot();
    return [
      '# HELP api_requests_total Total API requests',
      '# TYPE api_requests_total counter',
      `api_requests_total ${s.requestsTotal}`,
      '# HELP api_requests_failed_total Total 5xx API requests',
      '# TYPE api_requests_failed_total counter',
      `api_requests_failed_total ${s.requestsFailed}`,
      '# HELP api_request_duration_ms_p50 Request duration p50 in milliseconds',
      '# TYPE api_request_duration_ms_p50 gauge',
      `api_request_duration_ms_p50 ${s.p50Ms}`,
      '# HELP api_request_duration_ms_p95 Request duration p95 in milliseconds',
      '# TYPE api_request_duration_ms_p95 gauge',
      `api_request_duration_ms_p95 ${s.p95Ms}`,
      '# HELP api_request_duration_ms_p99 Request duration p99 in milliseconds',
      '# TYPE api_request_duration_ms_p99 gauge',
      `api_request_duration_ms_p99 ${s.p99Ms}`,
      '',
    ].join('\n');
  }
}

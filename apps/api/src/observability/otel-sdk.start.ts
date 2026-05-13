/**
 * OpenTelemetry Node SDK — must be imported before any module that loads @prisma/client
 * so PrismaInstrumentation can hook the client (see main.ts import order).
 *
 * Enable by setting OTEL_EXPORTER_OTLP_TRACES_ENDPOINT or OTEL_EXPORTER_OTLP_ENDPOINT.
 * Standard env: OTEL_SERVICE_NAME, OTEL_RESOURCE_ATTRIBUTES, OTEL_TRACES_SAMPLER_ARG, etc.
 */
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { PrismaInstrumentation } from '@prisma/instrumentation';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { NodeSDK } from '@opentelemetry/sdk-node';

function resolveOtlpTracesUrl(): string | null {
  const direct = process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT?.trim();
  if (direct) {
    return direct;
  }
  const base = process.env.OTEL_EXPORTER_OTLP_ENDPOINT?.trim();
  if (!base) {
    return null;
  }
  return `${base.replace(/\/+$/, '')}/v1/traces`;
}

const tracesUrl = resolveOtlpTracesUrl();
if (!tracesUrl) {
  // Intentionally silent: tracing is optional in dev/test.
} else {
  const serviceName =
    process.env.OTEL_SERVICE_NAME?.trim() ||
    process.env.npm_package_name?.trim() ||
    'chisto-api';

  const headers = parseOtlpHeaders();
  const traceExporter = new OTLPTraceExporter(
    headers != null ? { url: tracesUrl, headers } : { url: tracesUrl },
  );

  const sdk = new NodeSDK({
    resource: resourceFromAttributes({
      'service.name': serviceName,
    }),
    traceExporter,
    instrumentations: [
      getNodeAutoInstrumentations({
        '@opentelemetry/instrumentation-fs': { enabled: false },
        '@opentelemetry/instrumentation-dns': { enabled: false },
      }),
      new PrismaInstrumentation(),
    ],
  });

  sdk.start();

  const shutdown = (): void => {
    void sdk.shutdown().catch(() => {});
  };
  process.once('beforeExit', shutdown);
  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
}

function parseOtlpHeaders(): Record<string, string> | undefined {
  const raw = process.env.OTEL_EXPORTER_OTLP_HEADERS?.trim();
  if (!raw) {
    return undefined;
  }
  const out: Record<string, string> = {};
  for (const pair of raw.split(',')) {
    const idx = pair.indexOf('=');
    if (idx === -1) {
      continue;
    }
    const k = pair.slice(0, idx).trim();
    const v = pair.slice(idx + 1).trim();
    if (k) {
      out[k] = v;
    }
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

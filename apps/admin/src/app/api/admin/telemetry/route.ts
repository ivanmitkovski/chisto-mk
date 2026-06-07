import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminCsrf } from '@/lib/auth';
import {
  checkPublicRouteRateLimit,
  readRequestBodyWithCap,
} from '@/lib/auth/public-route-rate-limit';
import { logger } from '@/lib/observability';

export const dynamic = 'force-dynamic';

const MAX_BODY_BYTES = 65_536;
const MAX_EVENTS = 50;

type ClientTelemetryEvent = {
  level?: string;
  message?: string;
  requestId?: string;
  context?: Record<string, unknown>;
};

type TelemetryBody = {
  events?: ClientTelemetryEvent[];
  level?: string;
  message?: string;
};

export async function POST(request: NextRequest) {
  if (!checkPublicRouteRateLimit(request, 'admin:telemetry')) {
    return NextResponse.json(
      { code: 'RATE_LIMITED', message: 'Too many telemetry requests.' },
      { status: 429 },
    );
  }

  if (!verifyAdminCsrf(request)) {
    return NextResponse.json({ code: 'CSRF_TOKEN_INVALID' }, { status: 403 });
  }

  const bodyResult = await readRequestBodyWithCap(request, MAX_BODY_BYTES);
  if (!bodyResult.ok) {
    return bodyResult.response;
  }

  let body: TelemetryBody | null = null;
  try {
    body = JSON.parse(bodyResult.text) as TelemetryBody;
  } catch {
    return NextResponse.json({ code: 'BAD_REQUEST', message: 'Invalid JSON body.' }, { status: 400 });
  }

  const requestId = request.headers.get('x-request-id') ?? undefined;

  const events: ClientTelemetryEvent[] =
    body && Array.isArray(body.events)
      ? body.events.slice(0, MAX_EVENTS)
      : body?.message || body?.level
        ? [{ ...(body.level ? { level: body.level } : {}), ...(body.message ? { message: body.message } : {}) }]
        : [];

  for (const event of events) {
    const level =
      event.level === 'error' || event.level === 'warn' || event.level === 'debug'
        ? event.level
        : 'info';
    const message = typeof event.message === 'string' ? event.message : 'client_telemetry';
    const resolvedRequestId = event.requestId ?? requestId;
    logger[level](message, {
      source: 'admin-client',
      ...(resolvedRequestId !== undefined ? { requestId: resolvedRequestId } : {}),
      ...(event.context ?? {}),
    });
  }

  return NextResponse.json({ ok: true }, { status: 202 });
}

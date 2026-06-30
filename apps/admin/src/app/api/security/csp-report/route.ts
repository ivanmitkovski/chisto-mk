import { NextRequest, NextResponse } from 'next/server';
import {
  checkPublicRouteRateLimit,
  readRequestBodyWithCap,
} from '@/lib/auth/public-route-rate-limit';
import { logger } from '@/lib/observability';

export const dynamic = 'force-dynamic';

const MAX_BODY_BYTES = 16_384;

export async function POST(request: NextRequest) {
  if (!checkPublicRouteRateLimit(request, 'security:csp-report')) {
    return NextResponse.json({ ok: true }, { status: 202 });
  }

  const bodyResult = await readRequestBodyWithCap(request, MAX_BODY_BYTES);
  if (!bodyResult.ok) {
    return bodyResult.response;
  }

  let payload: unknown = null;
  try {
    payload = bodyResult.text ? JSON.parse(bodyResult.text) : null;
  } catch {
    return NextResponse.json({ ok: true }, { status: 202 });
  }

  const requestId = request.headers.get('x-request-id') ?? crypto.randomUUID();
  logger.warn('csp_violation', {
    requestId,
    context: {
      payload,
      userAgent: request.headers.get('user-agent') ?? undefined,
    },
  });
  return NextResponse.json({ ok: true }, { status: 202 });
}

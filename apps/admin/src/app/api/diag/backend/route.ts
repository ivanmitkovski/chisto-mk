import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';

export const dynamic = 'force-dynamic';

/**
 * Temporary ops: set ADMIN_DIAG_KEY in Vercel, then open
 * /api/diag/backend?key=YOUR_KEY
 * to see whether the deployment can fetch the API /health (same path as RSC).
 */
export async function GET(request: NextRequest) {
  const expected = process.env.ADMIN_DIAG_KEY?.trim();
  const key = request.nextUrl.searchParams.get('key') ?? '';
  if (!expected || key !== expected) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  const base = getApiBaseUrl();
  try {
    const r = await fetch(`${base}/health`, { cache: 'no-store' });
    const text = await r.text();
    return NextResponse.json({
      resolvedBase: base,
      healthHttpStatus: r.status,
      ok: r.ok,
      bodyPreview: text.slice(0, 300),
    });
  } catch (e) {
    const err = e instanceof Error ? e : new Error(String(e));
    return NextResponse.json({
      resolvedBase: base,
      ok: false,
      errorName: err.name,
      errorMessage: err.message,
      errorCause: err.cause instanceof Error ? err.cause.message : String(err.cause ?? ''),
    });
  }
}

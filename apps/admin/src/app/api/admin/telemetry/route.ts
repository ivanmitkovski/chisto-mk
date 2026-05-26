import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminCsrf } from '@/lib/server/admin-session';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  if (!verifyAdminCsrf(request)) {
    return NextResponse.json({ code: 'CSRF_TOKEN_INVALID' }, { status: 403 });
  }
  const event = await request.json().catch(() => null);
  console.info('[admin:telemetry]', {
    requestId: request.headers.get('x-request-id'),
    event,
    at: new Date().toISOString(),
  });
  return NextResponse.json({ ok: true }, { status: 202 });
}

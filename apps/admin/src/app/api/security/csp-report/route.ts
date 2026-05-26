import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  const payload = await request.json().catch(() => null);
  if (process.env.NODE_ENV !== 'test') {
    console.warn('[admin:csp-report]', payload);
  }
  return NextResponse.json({ ok: true }, { status: 202 });
}

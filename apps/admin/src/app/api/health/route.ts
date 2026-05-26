import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json({
    status: 'ok',
    service: 'chisto-admin-bff',
    timestamp: new Date().toISOString(),
  });
}

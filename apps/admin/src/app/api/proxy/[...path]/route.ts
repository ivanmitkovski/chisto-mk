import { NextRequest } from 'next/server';
import { proxyBackendWithRefresh } from '@/lib/admin-api-with-refresh';

export const dynamic = 'force-dynamic';

type RouteContext = {
  params: Promise<{ path?: string[] }>;
};

async function handle(request: NextRequest, context: RouteContext) {
  const { path = [] } = await context.params;
  const targetPath = `/${path.map(encodeURIComponent).join('/')}`;
  const search = request.nextUrl.search;
  return proxyBackendWithRefresh(`${targetPath}${search}`, request);
}

export function GET(request: NextRequest, context: RouteContext) {
  return handle(request, context);
}

export function POST(request: NextRequest, context: RouteContext) {
  return handle(request, context);
}

export function PATCH(request: NextRequest, context: RouteContext) {
  return handle(request, context);
}

export function DELETE(request: NextRequest, context: RouteContext) {
  return handle(request, context);
}

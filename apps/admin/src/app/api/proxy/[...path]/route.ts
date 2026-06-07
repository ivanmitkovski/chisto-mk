import { NextRequest } from 'next/server';
import { proxyBackendWithRefresh } from '@/lib/auth';
import { isProxyPathAllowed, normalizeProxyPathSegments } from '@/lib/auth/proxy-path-policy';

export const dynamic = 'force-dynamic';

type RouteContext = {
  params: Promise<{ path?: string[] }>;
};

async function handle(request: NextRequest, context: RouteContext) {
  const { path = [] } = await context.params;
  const targetPath = normalizeProxyPathSegments(path);
  if (!targetPath || !isProxyPathAllowed(targetPath)) {
    return Response.json({ code: 'PROXY_PATH_FORBIDDEN', message: 'Path not allowed.' }, { status: 403 });
  }
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

import type { Request } from 'express';

export function clientIp(req: Request, xff?: string): string | null {
  const fromTrustedProxy = req.ip?.trim();
  if (fromTrustedProxy != null && fromTrustedProxy.length > 0) {
    return fromTrustedProxy;
  }
  const firstForwarded = xff?.split(',')[0]?.trim();
  if (firstForwarded == null || firstForwarded.length === 0) {
    return null;
  }
  return firstForwarded;
}

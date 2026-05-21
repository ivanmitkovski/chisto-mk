export const API_VERSION = 'v1' as const;

export type ApiErrorEnvelope = {
  code: string;
  message: string;
  details?: unknown;
};

export function apiPath(path: string): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  return normalized.startsWith('/v1') ? normalized : `/v1${normalized}`;
}

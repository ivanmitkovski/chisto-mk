import { timingSafeEqual } from 'node:crypto';

export type JwtSecretEntry = { kid: string; secret: string };

/** Resolve HS256 secrets for JWT verify/sign; supports rotation via JWT_SECRET_PREVIOUS + JWT_KID_PREVIOUS. */
export function resolveJwtSecretsFromEnv(env: NodeJS.ProcessEnv = process.env): JwtSecretEntry[] {
  const currentKid = env.JWT_KID?.trim() || 'default';
  const currentSecret = env.JWT_SECRET?.trim() ?? '';
  if (!currentSecret) {
    return [];
  }
  const entries: JwtSecretEntry[] = [{ kid: currentKid, secret: currentSecret }];
  const prevSecret = env.JWT_SECRET_PREVIOUS?.trim();
  const prevKid = env.JWT_KID_PREVIOUS?.trim() || 'previous';
  if (prevSecret && prevSecret !== currentSecret) {
    entries.push({ kid: prevKid, secret: prevSecret });
  }
  return entries;
}

export function secretForKid(kid: string | undefined, entries: JwtSecretEntry[]): string | null {
  if (entries.length === 0) return null;
  const normalized = kid?.trim();
  if (!normalized) {
    return entries[0]?.secret ?? null;
  }
  const match = entries.find((e) => safeKidEqual(e.kid, normalized));
  return match?.secret ?? entries[0]?.secret ?? null;
}

export function defaultJwtKid(entries: JwtSecretEntry[]): string {
  return entries[0]?.kid ?? 'default';
}

function safeKidEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'utf8');
  const bufB = Buffer.from(b, 'utf8');
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

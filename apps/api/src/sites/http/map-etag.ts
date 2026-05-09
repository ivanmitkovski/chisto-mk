import { createHash } from 'node:crypto';

export function weakEtagForMapBody(body: {
  data: Array<{ id: string; updatedAt?: Date | string }>;
  meta?: { dataVersion?: string; queryMode?: string; [key: string]: unknown };
}): string {
  const h = createHash('sha1');
  for (const row of body.data) {
    h.update(row.id);
    const updated =
      row.updatedAt instanceof Date ? row.updatedAt.toISOString() : String(row.updatedAt ?? '');
    h.update(updated);
  }
  h.update(String(body.meta?.dataVersion ?? ''));
  h.update(String(body.meta?.queryMode ?? ''));
  return `W/"${h.digest('hex').slice(0, 24)}"`;
}

export function weakEtagForJson(value: unknown): string {
  const h = createHash('sha1');
  h.update(JSON.stringify(value) ?? '');
  return `W/"${h.digest('hex').slice(0, 24)}"`;
}

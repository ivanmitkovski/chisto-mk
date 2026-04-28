import { createHash } from 'node:crypto';

export function weakEtagForMapBody(body: {
  data: Array<{ id: string; updatedAt?: Date | string }>;
}): string {
  const h = createHash('sha1');
  for (const row of body.data) {
    h.update(row.id);
    const updated =
      row.updatedAt instanceof Date ? row.updatedAt.toISOString() : String(row.updatedAt ?? '');
    h.update(updated);
  }
  return `W/"${h.digest('hex').slice(0, 24)}"`;
}

import { z } from 'zod';

export const auditMetadataSchema = z.record(z.string(), z.unknown()).optional();

export function parseAuditMetadata(value: unknown): Record<string, unknown> | undefined {
  const parsed = auditMetadataSchema.safeParse(value);
  return parsed.success ? (parsed.data as Record<string, unknown>) : undefined;
}

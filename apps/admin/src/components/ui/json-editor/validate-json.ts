export type JsonValidationResult =
  | { valid: true; parsed?: unknown }
  | { valid: false; error: string };

export function validateJson(value: string): JsonValidationResult {
  if (!value.trim()) {
    return { valid: true };
  }

  try {
    return { valid: true, parsed: JSON.parse(value) as unknown };
  } catch (error) {
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Invalid JSON',
    };
  }
}

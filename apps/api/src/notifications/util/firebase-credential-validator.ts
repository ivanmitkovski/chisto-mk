export type FirebaseCredentialStatus =
  | 'valid'
  | 'missing'
  | 'invalid_json'
  | 'invalid_structure';

export type FirebaseCredentialValidation = {
  status: FirebaseCredentialStatus;
  projectId: string | null;
  parseError: string | null;
};

const REQUIRED_KEYS = ['type', 'project_id', 'private_key', 'client_email'] as const;

function sanitizeParseError(message: string): string {
  return message.slice(0, 200).replace(/[\r\n]+/g, ' ');
}

export function validateFirebaseServiceAccountJson(
  raw: string | undefined,
): FirebaseCredentialValidation {
  if (raw == null || raw.trim().length === 0) {
    return { status: 'missing', projectId: null, parseError: null };
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      status: 'invalid_json',
      projectId: null,
      parseError: sanitizeParseError(message),
    };
  }

  if (parsed == null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return {
      status: 'invalid_structure',
      projectId: null,
      parseError: 'Expected a JSON object',
    };
  }

  const record = parsed as Record<string, unknown>;
  for (const key of REQUIRED_KEYS) {
    const value = record[key];
    if (typeof value !== 'string' || value.trim().length === 0) {
      return {
        status: 'invalid_structure',
        projectId: typeof record.project_id === 'string' ? record.project_id : null,
        parseError: `Missing or invalid field: ${key}`,
      };
    }
  }

  if (record.type !== 'service_account') {
    return {
      status: 'invalid_structure',
      projectId: record.project_id as string,
      parseError: 'type must be service_account',
    };
  }

  return {
    status: 'valid',
    projectId: record.project_id as string,
    parseError: null,
  };
}

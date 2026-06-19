import { validateFirebaseServiceAccountJson } from '../../src/notifications/util/firebase-credential-validator';

describe('validateFirebaseServiceAccountJson', () => {
  it('returns missing when env is empty', () => {
    expect(validateFirebaseServiceAccountJson(undefined)).toEqual({
      status: 'missing',
      projectId: null,
      parseError: null,
    });
  });

  it('returns invalid_json for malformed JSON', () => {
    const result = validateFirebaseServiceAccountJson('{"type":');
    expect(result.status).toBe('invalid_json');
    expect(result.parseError).toBeTruthy();
  });

  it('returns valid for well-formed service account JSON', () => {
    const json = JSON.stringify({
      type: 'service_account',
      project_id: 'chisto-mk-dev',
      private_key: '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----\\n',
      client_email: 'firebase-adminsdk@test.iam.gserviceaccount.com',
    });
    expect(validateFirebaseServiceAccountJson(json)).toEqual({
      status: 'valid',
      projectId: 'chisto-mk-dev',
      parseError: null,
    });
  });

  it('returns invalid_structure when required keys are missing', () => {
    const json = JSON.stringify({ type: 'service_account', project_id: 'x' });
    const result = validateFirebaseServiceAccountJson(json);
    expect(result.status).toBe('invalid_structure');
    expect(result.parseError).toContain('private_key');
  });
});

/** FCM error codes that mean the device token should be revoked (no retry). */
export const FCM_REVOKE_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
  'messaging/mismatched-credential',
  'messaging/sender-id-mismatch',
]);

/** Firebase ↔ APNs/Web Push or Admin SDK credential misconfiguration — retries will not help. */
export const FCM_CONFIG_ERROR_CODES = new Set([
  'messaging/third-party-auth-error',
  'messaging/invalid-apns-credentials',
  'messaging/authentication-error',
]);

export function remediationForFcmErrorCode(code: string | null | undefined): string | null {
  if (!code) {
    return null;
  }
  if (code === 'messaging/third-party-auth-error' || code === 'messaging/invalid-apns-credentials') {
    return (
      'Upload the matching-environment APNs Auth Key (.p8) in Firebase Console → Project settings → ' +
      'Cloud Messaging. Debug iOS builds require a Development APNs auth key; production/TestFlight require Production.'
    );
  }
  if (code === 'messaging/authentication-error') {
    return 'Verify FIREBASE_SERVICE_ACCOUNT_JSON matches the Firebase project used by the mobile app.';
  }
  if (FCM_REVOKE_ERROR_CODES.has(code)) {
    return 'Device tokens are invalid or unregistered. Purge undeliverable dead letters after users re-open the app.';
  }
  if (code === 'FCM_NOT_READY') {
    return 'FCM is enabled but Firebase Admin failed to initialize. Check FIREBASE_SERVICE_ACCOUNT_JSON.';
  }
  return null;
}

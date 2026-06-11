/// Structured reason for local session teardown (no PII).
enum SessionTeardownReason {
  resumeRefreshRejected('resume_refresh_rejected'),
  proactiveRefreshRejected('proactive_refresh_rejected'),
  rest401AfterRefresh('rest_401_after_refresh'),
  realtimeAuthRejected('realtime_auth_rejected'),
  coldRestoreRejected('cold_restore_rejected'),
  explicitSignOut('explicit_sign_out'),
  sessionInvalidationUi('session_invalidation_ui'),
  forced('forced');

  const SessionTeardownReason(this.logLabel);

  final String logLabel;
}

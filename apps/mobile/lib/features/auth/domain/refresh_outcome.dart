/// Result of a background session refresh (REST `/auth/refresh` or equivalent).
enum RefreshOutcome {
  success,
  serverRejected,
  transient,
}

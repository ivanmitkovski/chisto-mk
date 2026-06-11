import 'dart:math' as math;

/// Shared refresh retry policy for foreground and background token rotation.
const int kAuthRefreshInvalidTokenMaxAttempts = 3;
const Duration kAuthRefreshInvalidTokenBaseDelay = Duration(milliseconds: 150);

Future<void> authRefreshInvalidTokenBackoff({math.Random? random}) async {
  final math.Random rng = random ?? math.Random();
  final int jitterMs = rng.nextInt(200);
  await Future<void>.delayed(
    kAuthRefreshInvalidTokenBaseDelay + Duration(milliseconds: jitterMs),
  );
}

/// Returns true when the refresh error may resolve after rotation replay.
bool isAuthRefreshRotationRaceError(String code) {
  return code == 'INVALID_REFRESH_TOKEN';
}

/// Returns true when the server definitively rejected the session.
bool isAuthRefreshServerRejectedError(String code) {
  switch (code) {
    case 'UNAUTHORIZED':
    case 'INVALID_TOKEN_USER':
    case 'SESSION_REVOKED':
      return true;
    default:
      return false;
  }
}

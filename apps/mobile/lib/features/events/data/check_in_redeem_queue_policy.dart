import 'package:chisto_mobile/core/errors/app_error.dart';

/// Whether a failed redeem should drop the [CheckInSyncQueue] entry.
///
/// Matches server semantics: conflicts, stale QR/session, or malformed payload
/// will not succeed on retry with the same `qrPayload`.
bool shouldRemoveQueuedCheckInAfterRedeemError(AppError error) {
  switch (error.code) {
    case 'CHECK_IN_REPLAY':
    case 'CHECK_IN_ALREADY_CHECKED_IN':
    case 'CHECK_IN_ALREADY_RECORDED':
    case 'CONFLICT':
    case 'CHECK_IN_QR_EXPIRED':
    case 'CHECK_IN_SESSION_MISMATCH':
    case 'CHECK_IN_INVALID_QR':
    case 'CHECK_IN_WRONG_EVENT':
    case 'CHECK_IN_LIFECYCLE':
    case 'CHECK_IN_SESSION_CLOSED':
    case 'CHECK_IN_NO_SESSION':
    case 'CHECK_IN_NOT_FOUND':
    case 'CHECK_IN_REQUEST_EXPIRED':
    case 'CHECK_IN_REQUEST_NOT_FOUND':
      return true;
    default:
      return false;
  }
}

import 'package:chisto_mobile/core/errors/app_error.dart';

/// Cooperative cancellation for API calls. Does not abort TCP; callers ignore
/// late results when [isCancelled] is true after await.
class RequestCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw AppError.cancelled(message: 'Request cancelled');
    }
  }
}

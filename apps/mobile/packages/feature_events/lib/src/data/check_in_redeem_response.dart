/// Parses POST `/events/:id/check-in/redeem` JSON (`checkedInAt` at root or under `data`).
DateTime? redeemResponseCheckedInAt(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  String? iso;
  final Object? top = json['checkedInAt'];
  if (top is String && top.isNotEmpty) {
    iso = top;
  } else {
    final Object? data = json['data'];
    if (data is Map<String, dynamic>) {
      final Object? inner = data['checkedInAt'];
      if (inner is String && inner.isNotEmpty) {
        iso = inner;
      }
    }
  }
  if (iso == null) {
    return null;
  }
  final DateTime? parsed = DateTime.tryParse(iso);
  return parsed?.toLocal();
}

/// Redeem `status` when the server defers confirmation to the organizer.
bool redeemResponseIsPendingConfirmation(Map<String, dynamic>? json) {
  if (json == null) {
    return false;
  }
  final String? status = json['status'] as String?;
  return status == 'pending_confirmation';
}

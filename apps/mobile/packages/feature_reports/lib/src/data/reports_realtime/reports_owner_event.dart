class ReportsOwnerEvent {
  const ReportsOwnerEvent({
    required this.eventId,
    required this.type,
    required this.ownerId,
    required this.reportId,
    required this.occurredAtMs,
    required this.mutationKind,
    this.status,
  });

  final String eventId;
  final String type;
  final String ownerId;
  final String reportId;
  final int occurredAtMs;
  final String mutationKind;
  final String? status;

  static ReportsOwnerEvent? tryFromJson(Map<String, dynamic> json) {
    final Object? eventId = json['eventId'];
    final Object? type = json['type'];
    final Object? ownerId = json['ownerId'];
    final Object? reportId = json['reportId'];
    final Object? occurredAtMs = json['occurredAtMs'];
    final Object? mutation = json['mutation'];

    if (eventId is! String ||
        type is! String ||
        ownerId is! String ||
        reportId is! String) {
      return null;
    }

    final int? occurred = occurredAtMs is int
        ? occurredAtMs
        : occurredAtMs is num
        ? occurredAtMs.toInt()
        : null;
    if (occurred == null) return null;

    String mutationKind = 'updated';
    String? status;
    if (mutation is Map<String, dynamic>) {
      final Object? kind = mutation['kind'];
      if (kind is String && kind.isNotEmpty) mutationKind = kind;
      final Object? st = mutation['status'];
      if (st is String && st.isNotEmpty) status = st;
    }

    return ReportsOwnerEvent(
      eventId: eventId,
      type: type,
      ownerId: ownerId,
      reportId: reportId,
      occurredAtMs: occurred,
      mutationKind: mutationKind,
      status: status,
    );
  }
}

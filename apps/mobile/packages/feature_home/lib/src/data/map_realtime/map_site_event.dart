class MapSiteEvent {
  const MapSiteEvent({
    required this.eventId,
    required this.type,
    required this.siteId,
    required this.occurredAtMs,
    required this.updatedAt,
    required this.mutationKind,
    this.status,
    this.latitude,
    this.longitude,
  });

  final String eventId;
  final String type;
  final String siteId;
  final int occurredAtMs;
  final DateTime updatedAt;
  final String mutationKind;
  final String? status;
  final double? latitude;
  final double? longitude;

  static MapSiteEvent? tryFromJson(Map<String, dynamic> json) {
    final Object? eventId = json['eventId'];
    final Object? type = json['type'];
    final Object? siteId = json['siteId'];
    final Object? occurredAtMs = json['occurredAtMs'];
    final Object? updatedAtRaw = json['updatedAt'];
    if (eventId is! String ||
        type is! String ||
        siteId is! String ||
        updatedAtRaw is! String) {
      return null;
    }
    final DateTime? updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null) {
      return null;
    }
    final int? occurred = occurredAtMs is int
        ? occurredAtMs
        : occurredAtMs is num
        ? occurredAtMs.toInt()
        : null;
    if (occurred == null) {
      return null;
    }
    final Object? mutationRaw = json['mutation'];
    String mutationKind = 'updated';
    String? status;
    double? latitude;
    double? longitude;
    if (mutationRaw is Map<String, dynamic>) {
      final Object? kindRaw = mutationRaw['kind'];
      if (kindRaw is String && kindRaw.isNotEmpty) {
        mutationKind = kindRaw;
      }
      final Object? statusRaw = mutationRaw['status'];
      if (statusRaw is String && statusRaw.isNotEmpty) {
        status = statusRaw;
      }
      final Object? latRaw = mutationRaw['latitude'];
      if (latRaw is num) {
        latitude = latRaw.toDouble();
      }
      final Object? lngRaw = mutationRaw['longitude'];
      if (lngRaw is num) {
        longitude = lngRaw.toDouble();
      }
    }
    return MapSiteEvent(
      eventId: eventId,
      type: type,
      siteId: siteId,
      occurredAtMs: occurred,
      updatedAt: updatedAt,
      mutationKind: mutationKind,
      status: status,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

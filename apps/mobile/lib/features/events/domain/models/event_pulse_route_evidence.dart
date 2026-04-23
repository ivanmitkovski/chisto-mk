import 'package:flutter/foundation.dart';

/// Server-backed route segment for cleanup progress UI.
@immutable
class EventRouteSegmentModel {
  const EventRouteSegmentModel({
    required this.id,
    required this.sortOrder,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.label,
    this.claimedByUserId,
    this.claimedAt,
    this.completedAt,
  });

  factory EventRouteSegmentModel.fromJson(Map<String, dynamic> json) {
    return EventRouteSegmentModel(
      id: json['id'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      label: json['label'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'open',
      claimedByUserId: json['claimedByUserId'] as String?,
      claimedAt: json['claimedAt'] == null
          ? null
          : DateTime.tryParse(json['claimedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }

  final String id;
  final int sortOrder;
  final String? label;
  final double latitude;
  final double longitude;
  final String status;
  final String? claimedByUserId;
  final DateTime? claimedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRouteSegmentModel &&
          id == other.id &&
          sortOrder == other.sortOrder &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          status == other.status &&
          label == other.label &&
          claimedByUserId == other.claimedByUserId &&
          claimedAt == other.claimedAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
    id,
    sortOrder,
    latitude,
    longitude,
    status,
    label,
    claimedByUserId,
    claimedAt,
    completedAt,
  );
}

/// Before/after/field evidence strip item (signed URLs from API).
@immutable
class EventEvidenceStripItem {
  const EventEvidenceStripItem({
    required this.id,
    required this.kind,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  factory EventEvidenceStripItem.fromJson(Map<String, dynamic> json) {
    return EventEvidenceStripItem(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'field',
      imageUrl: json['imageUrl'] as String? ?? '',
      caption: json['caption'] as String?,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
    );
  }

  final String id;
  final String kind;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventEvidenceStripItem &&
          id == other.id &&
          kind == other.kind &&
          imageUrl == other.imageUrl &&
          caption == other.caption &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, kind, imageUrl, caption, createdAt);
}

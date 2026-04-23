import 'package:flutter/foundation.dart';

/// Server `completeness` on `GET /events/:id/impact-receipt`.
enum EventImpactReceiptCompleteness {
  inProgress,
  full,
  partialMissingAfter,
  partialMissingEvidence,
  partialMissingAfterAndEvidence,
}

@immutable
class EventImpactReceiptEvidenceItem {
  const EventImpactReceiptEvidenceItem({
    required this.id,
    required this.kind,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
}

@immutable
class EventImpactReceipt {
  const EventImpactReceipt({
    required this.eventId,
    required this.title,
    required this.siteLabel,
    required this.scheduledAt,
    required this.endAt,
    required this.lifecycleStatus,
    required this.participantCount,
    required this.checkedInCount,
    required this.reportedBagsCollected,
    required this.bagsUpdatedAt,
    required this.evidence,
    required this.afterImageUrls,
    required this.completeness,
    required this.asOf,
    required this.organizerName,
  });

  final String eventId;
  final String title;
  final String siteLabel;
  final DateTime scheduledAt;
  final DateTime? endAt;
  final String lifecycleStatus;
  final int participantCount;
  final int checkedInCount;
  final int reportedBagsCollected;
  final DateTime? bagsUpdatedAt;
  final List<EventImpactReceiptEvidenceItem> evidence;
  final List<String> afterImageUrls;
  final EventImpactReceiptCompleteness completeness;
  final DateTime asOf;
  final String organizerName;
}

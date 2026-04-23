import 'package:chisto_mobile/features/events/domain/models/event_impact_receipt.dart';

EventImpactReceiptCompleteness _parseCompleteness(String raw) {
  switch (raw) {
    case 'in_progress':
      return EventImpactReceiptCompleteness.inProgress;
    case 'full':
      return EventImpactReceiptCompleteness.full;
    case 'partial_missing_after':
      return EventImpactReceiptCompleteness.partialMissingAfter;
    case 'partial_missing_evidence':
      return EventImpactReceiptCompleteness.partialMissingEvidence;
    case 'partial_missing_after_and_evidence':
      return EventImpactReceiptCompleteness.partialMissingAfterAndEvidence;
    default:
      return EventImpactReceiptCompleteness.partialMissingAfterAndEvidence;
  }
}

EventImpactReceipt eventImpactReceiptFromJson(Map<String, dynamic> json) {
  final List<dynamic> evidenceRaw = json['evidence'] as List<dynamic>? ?? const <dynamic>[];
  final List<EventImpactReceiptEvidenceItem> evidence = evidenceRaw
      .map((dynamic e) => e as Map<String, dynamic>)
      .map(
        (Map<String, dynamic> e) => EventImpactReceiptEvidenceItem(
          id: e['id']! as String,
          kind: e['kind']! as String,
          imageUrl: e['imageUrl']! as String,
          caption: e['caption'] as String?,
          createdAt: DateTime.parse(e['createdAt']! as String),
        ),
      )
      .toList();

  final List<dynamic> afterRaw = json['afterImageUrls'] as List<dynamic>? ?? const <dynamic>[];
  final List<String> afterUrls = afterRaw.map((dynamic u) => u as String).toList();

  return EventImpactReceipt(
    eventId: json['eventId']! as String,
    title: json['title']! as String,
    siteLabel: json['siteLabel']! as String,
    scheduledAt: DateTime.parse(json['scheduledAt']! as String),
    endAt: json['endAt'] != null ? DateTime.parse(json['endAt']! as String) : null,
    lifecycleStatus: json['lifecycleStatus']! as String,
    participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
    reportedBagsCollected: (json['reportedBagsCollected'] as num?)?.toInt() ?? 0,
    bagsUpdatedAt:
        json['bagsUpdatedAt'] != null ? DateTime.parse(json['bagsUpdatedAt']! as String) : null,
    evidence: evidence,
    afterImageUrls: afterUrls,
    completeness: _parseCompleteness(json['completeness']! as String),
    asOf: DateTime.parse(json['asOf']! as String),
    organizerName: json['organizerName']! as String,
  );
}

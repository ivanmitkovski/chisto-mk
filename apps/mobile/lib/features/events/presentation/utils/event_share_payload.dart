import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_impact_receipt.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Normalizes [AppConfig.shareBaseUrlFromEnvironment] (no trailing slash).
String normalizedShareBaseUrl([String? raw]) {
  final String base = (raw ?? AppConfig.shareBaseUrlFromEnvironment).trim();
  return base.replaceAll(RegExp(r'/+$'), '');
}

/// Public web URL for an event (used in share sheets and clipboard).
String eventSharePageUrl(String shareBaseUrl, String eventId) {
  return '${normalizedShareBaseUrl(shareBaseUrl)}/events/$eventId';
}

/// HTTPS URI suitable for [Share.shareUri] on iOS (richer link preview when OG exists).
Uri? eventShareHttpsUri(String shareBaseUrl, String eventId) {
  final Uri uri = Uri.parse(eventSharePageUrl(shareBaseUrl, eventId));
  if (uri.scheme != 'https') {
    return null;
  }
  if (!uri.hasAuthority || uri.authority.isEmpty) {
    return null;
  }
  return uri;
}

/// Multiline plain text: title, schedule, site, blank line, URL (for clipboard / SMS fallback).
String buildEventSharePlainText(
  BuildContext context,
  EcoEvent event,
  String shareBaseUrl,
) {
  final String link = eventSharePageUrl(shareBaseUrl, event.id);
  return '${event.title}\n${formatEventCalendarDate(context, event.date)} (${event.formattedTimeRange})\n${event.siteName}\n\n$link';
}

/// Plain text for sharing an [EventImpactReceipt] (counts only; no roster).
String buildImpactReceiptSharePlainText(
  AppLocalizations l10n,
  EventImpactReceipt receipt,
  String shareBaseUrl,
) {
  final String link = eventSharePageUrl(shareBaseUrl, receipt.eventId);
  final String summary = l10n.eventsImpactReceiptShareSummary(
    receipt.checkedInCount,
    receipt.reportedBagsCollected,
    receipt.participantCount,
  );
  return '${receipt.title}\n${receipt.siteLabel}\n$summary\n\n$link';
}

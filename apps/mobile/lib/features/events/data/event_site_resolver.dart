import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/home/data/mock_pollution_sites.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:flutter/material.dart';

class EventSiteSummary {
  const EventSiteSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.distanceKm,
    required this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final String description;
  final double distanceKm;
  final String imageUrl;

  /// Present when the backing [PollutionSite] or API row includes coordinates.
  final double? latitude;
  final double? longitude;

  factory EventSiteSummary.fromPollutionSite(PollutionSite site) {
    final String? primary = site.primaryImageUrl?.trim();
    final String imageUrl = primary != null && primary.isNotEmpty
        ? primary
        : 'assets/images/references/onboarding_reference.png';
    return EventSiteSummary(
      id: site.id,
      title: site.title,
      description: site.description,
      distanceKm: site.distanceKm.toDouble(),
      imageUrl: imageUrl,
      latitude: site.latitude,
      longitude: site.longitude,
    );
  }

  factory EventSiteSummary.fromEvent(EcoEvent event) {
    return EventSiteSummary(
      id: event.siteId,
      title: event.siteName,
      description: event.description,
      distanceKm: event.siteDistanceKm,
      imageUrl: event.siteImageUrl,
    );
  }
}

class EventSiteResolver {
  const EventSiteResolver._();

  static List<PollutionSite> allSites() {
    final List<PollutionSite> sites = buildMockPollutionSites();
    sites.sort((PollutionSite a, PollutionSite b) {
      final int distance = a.distanceKm.compareTo(b.distanceKm);
      if (distance != 0) {
        return distance;
      }
      return a.title.compareTo(b.title);
    });
    return sites;
  }

  static PollutionSite? findSiteById(String siteId) {
    for (final PollutionSite site in allSites()) {
      if (site.id == siteId) {
        return site;
      }
    }
    return null;
  }

  static EventSiteSummary? findSiteSummaryById(String siteId) {
    final PollutionSite? site = findSiteById(siteId);
    return site == null ? null : EventSiteSummary.fromPollutionSite(site);
  }

  static EventSiteSummary? coerceSummary({
    String? siteId,
    String? siteName,
    String? siteImageUrl,
    double? siteDistanceKm,
    /// When the site is not in the mock catalog (synthetic row), shown as description.
    String syntheticSiteDescription = 'Community cleanup site',
  }) {
    if (siteId == null || siteId.isEmpty) {
      return null;
    }
    final EventSiteSummary? canonical = findSiteSummaryById(siteId);
    if (canonical != null) {
      return canonical;
    }
    if (siteName == null || siteName.trim().isEmpty) {
      return null;
    }
    return EventSiteSummary(
      id: siteId,
      title: siteName.trim(),
      description: syntheticSiteDescription,
      distanceKm: siteDistanceKm ?? 0,
      imageUrl:
          siteImageUrl ?? 'assets/images/references/onboarding_reference.png',
    );
  }

  /// [statusLabel] is shown on synthetic sites (not in the mock catalog). Pass a
  /// localized string from the UI layer; when null, uses [EcoEventStatus.label] (English).
  static PollutionSite resolveSiteForEvent(
    EcoEvent event, {
    String? statusLabel,
  }) {
    final PollutionSite? canonical = findSiteById(event.siteId);
    if (canonical != null) {
      return canonical;
    }
    final String cover = event.siteImageUrl.trim();
    final ImageProvider imageProvider;
    if (cover.isEmpty) {
      imageProvider =
          const AssetImage('assets/images/references/onboarding_reference.png');
    } else {
      final String lower = cover.toLowerCase();
      if (lower.startsWith('http://') || lower.startsWith('https://')) {
        imageProvider = NetworkImage(cover);
      } else if (cover.startsWith('assets/')) {
        imageProvider = AssetImage(cover);
      } else {
        imageProvider =
            const AssetImage('assets/images/references/onboarding_reference.png');
      }
    }
    return PollutionSite(
      id: event.siteId,
      title: event.siteName,
      description: event.description,
      statusLabel: statusLabel ?? event.status.label,
      statusColor: Color(event.status.colorValue),
      distanceKm: event.siteDistanceKm.toDouble(),
      score: event.participantCount,
      participantCount: event.participantCount,
      imageProvider: imageProvider,
      images: <ImageProvider>[imageProvider],
    );
  }

  static List<EcoEvent> eventsForSite({
    required String siteId,
    required List<EcoEvent> events,
  }) {
    final List<EcoEvent> matches = events
        .where((EcoEvent event) => event.siteId == siteId)
        .toList(growable: false);
    matches.sort((EcoEvent a, EcoEvent b) {
      if (a.status == EcoEventStatus.completed ||
          a.status == EcoEventStatus.cancelled) {
        return b.startDateTime.compareTo(a.startDateTime);
      }
      return a.startDateTime.compareTo(b.startDateTime);
    });
    return matches;
  }

  static List<CleaningEvent> cleaningEventsForSite({
    required String siteId,
    required List<EcoEvent> events,
    required String Function(EcoEventStatus status) statusLabelFor,
  }) {
    return eventsForSite(siteId: siteId, events: events)
        .map(
          (EcoEvent event) => CleaningEvent(
            id: event.id,
            title: event.title,
            dateTime: event.startDateTime,
            participantCount: event.participantCount,
            isOrganizer: event.isOrganizer,
            statusLabel: statusLabelFor(event.status),
            statusColor: Color(event.status.colorValue),
          ),
        )
        .toList(growable: false);
  }
}

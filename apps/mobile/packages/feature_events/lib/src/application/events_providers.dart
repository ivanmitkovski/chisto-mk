import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_events/src/data/api_event_analytics_repository.dart';
import 'package:feature_events/src/data/api_organizer_certification_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:feature_events/src/data/chat/http_event_chat_attachment_downloader.dart';
import 'package:feature_events/src/data/field_mode_sync_service.dart';
import 'package:feature_events/src/domain/repositories/check_in_repository.dart';
import 'package:feature_events/src/domain/repositories/event_chat_attachment_port.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/domain/repositories/organizer_certification_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart'
    show eventsFeedRefreshTickProvider;

EventsRepository? _eventsRepositoryTestOverride;
CheckInRepository? _checkInRepositoryTestOverride;
OrganizerCertificationRepositoryPort? _organizerCertificationRepositoryTestOverride;

/// Widget / integration tests can pin repositories without booting [AppBootstrap].
@visibleForTesting
void setEventsRepositoryTestOverride(EventsRepository? repository) {
  _eventsRepositoryTestOverride = repository;
}

@visibleForTesting
void setCheckInRepositoryTestOverride(CheckInRepository? repository) {
  _checkInRepositoryTestOverride = repository;
}

@visibleForTesting
void setOrganizerCertificationRepositoryTestOverride(
  OrganizerCertificationRepositoryPort? repository,
) {
  _organizerCertificationRepositoryTestOverride = repository;
}

@visibleForTesting
EventsRepository? get eventsRepositoryTestOverride =>
    _eventsRepositoryTestOverride;

/// Resolves [eventsRepositoryProvider] with test override support outside [ProviderScope].
EventsRepository readEventsRepository() {
  final EventsRepository? override = _eventsRepositoryTestOverride;
  if (override != null) {
    return override;
  }
  return readRoot(eventsRepositoryProvider);
}

/// Resolves [checkInRepositoryProvider] with test override support outside [ProviderScope].
CheckInRepository readCheckInRepository() {
  final CheckInRepository? override = _checkInRepositoryTestOverride;
  if (override != null) {
    return override;
  }
  return readRoot(checkInRepositoryProvider);
}

final eventsRepositoryProvider = Provider<EventsRepository>((Ref ref) {
  final EventsRepository? override = _eventsRepositoryTestOverride;
  if (override != null) {
    return override;
  }
  return ref.watch(appBootstrapProvider).eventsRepository;
});

final checkInRepositoryProvider = Provider<CheckInRepository>((Ref ref) {
  final CheckInRepository? override = _checkInRepositoryTestOverride;
  if (override != null) {
    return override;
  }
  return ref.watch(appBootstrapProvider).checkInRepository;
});

final eventChatRepositoryProvider = Provider<EventChatRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).eventChatRepository;
});

final eventAnalyticsRepositoryProvider = Provider<ApiEventAnalyticsRepository>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).eventAnalyticsRepository;
});

final organizerCertificationRepositoryProvider =
    Provider<OrganizerCertificationRepositoryPort>((Ref ref) {
      final OrganizerCertificationRepositoryPort? override =
          _organizerCertificationRepositoryTestOverride;
      if (override != null) {
        return override;
      }
      return ApiOrganizerCertificationRepository(
        client: ref.watch(apiClientProvider),
      );
    });

final fieldModeSyncServiceProvider = Provider<FieldModeSyncService>((Ref ref) {
  return FieldModeSyncService(client: ref.watch(apiClientProvider));
});

final eventChatAttachmentDownloaderProvider = Provider<EventChatAttachmentPort>(
  (Ref ref) {
    return HttpEventChatAttachmentDownloader();
  },
);

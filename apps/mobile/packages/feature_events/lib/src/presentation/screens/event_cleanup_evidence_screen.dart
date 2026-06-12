library;

// Upload/save UX: mirrors create-event and chat flows — explicit busy state on the
// primary action, [AppSnack] for recoverable errors, no separate async card (see
// [EventsAsyncSection] on detail for list-style retry surfaces).

import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:feature_events/src/presentation/widgets/cleanup_evidence/cleanup_evidence_save_result_dialog.dart';
import 'package:feature_events/src/presentation/widgets/cleanup_evidence/cleanup_evidence_widgets.dart';
import 'package:feature_events/src/presentation/widgets/event_cover_image.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_evidence_strip_section.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

part 'event_cleanup_evidence/event_cleanup_evidence_actions.dart';
part 'event_cleanup_evidence/event_cleanup_evidence_body.dart';

class EventCleanupEvidenceScreen extends StatefulWidget {
  const EventCleanupEvidenceScreen({
    super.key,
    required this.eventId,
    @visibleForTesting this.testPickAfterImagePathsOverride,
    @visibleForTesting this.testSetAfterImagesOverride,
  });

  final String eventId;

  /// Skips gallery + file copy; supplies local paths (widget tests).
  final Future<List<String>> Function()? testPickAfterImagePathsOverride;

  /// Replaces [EventsRepository.setAfterImages] (widget tests: errors / retries).
  final Future<bool> Function({
    required String eventId,
    required List<String> imagePaths,
  })?
  testSetAfterImagesOverride;

  @override
  State<EventCleanupEvidenceScreen> createState() =>
      _EventCleanupEvidenceScreenState();
}

class _EventCleanupEvidenceScreenState extends State<EventCleanupEvidenceScreen>
    with StateRebuildMixin {
  static const int _maxAfterImages = 8;
  static const double _heroHeight = 260;
  static const double _thumbSize = 64;
  static const double _thumbStripHeight = 74;

  EventsRepository get _eventsRepository => readEventsRepository();
  ImagePicker? _imagePicker;
  ImagePicker get _picker => _imagePicker ??= ImagePicker();
  final ValueNotifier<String> _tab = ValueNotifier<String>('after');

  List<String> _afterImages = <String>[];
  int _selectedIndex = 0;
  bool _isPicking = false;
  bool _isSaving = false;

  EcoEvent? get _event => _eventsRepository.findById(widget.eventId);

  @override
  void initState() {
    super.initState();
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _afterImages = List<String>.from(
      _event?.afterImagePaths ?? const <String>[],
    );
  }

  @override
  void dispose() {
    _eventsRepository.removeListener(_onRepoChanged);
    _tab.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    void apply() {
      if (!mounted) return;
      setState(() {});
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  @override
  Widget build(BuildContext context) => buildEventCleanupEvidenceBody(context);
}

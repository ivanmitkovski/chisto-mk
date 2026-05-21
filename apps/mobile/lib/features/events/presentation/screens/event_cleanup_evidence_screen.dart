library;


// Upload/save UX: mirrors create-event and chat flows — explicit busy state on the
// primary action, [AppSnack] for recoverable errors, no separate async card (see
// [EventsAsyncSection] on detail for list-style retry surfaces).

import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/cleanup_evidence/cleanup_evidence_save_result_dialog.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/cleanup_evidence/cleanup_evidence_widgets.dart';
import 'package:chisto_mobile/features/reports/data/report_photo_upload_prep.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_evidence_strip_section.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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
  })? testSetAfterImagesOverride;

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

  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
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
    _afterImages =
        List<String>.from(_event?.afterImagePaths ?? const <String>[]);
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

library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/socket_check_in_stream.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/organizer_end_soon_local_controller.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/extend_event_end_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/organizer_checkin/organizer_checkin_widgets.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/user_avatar_circle.dart';

/// Organizer check-in screen: displays a QR code attendees scan.
part 'organizer_checkin_screen_state.dart';
part 'organizer_checkin_confirm_sheet.dart';

/// After each scan the QR regenerates. Checked-in names appear in the list.
class OrganizerCheckInScreen extends StatefulWidget {
  const OrganizerCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<OrganizerCheckInScreen> createState() => _OrganizerCheckInScreenState();
}

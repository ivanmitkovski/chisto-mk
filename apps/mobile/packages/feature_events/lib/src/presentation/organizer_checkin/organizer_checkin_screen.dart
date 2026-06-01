library;

import 'dart:async';
import 'dart:math';

import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/socket_check_in_stream.dart';
import 'package:feature_events/src/domain/models/check_in_payload.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_participant_row.dart';
import 'package:feature_events/src/domain/repositories/check_in_repository.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_qr_session.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:feature_events/src/presentation/utils/organizer_end_soon_local_controller.dart';
import 'package:feature_events/src/presentation/widgets/extend_event_end_sheet.dart';
import 'package:feature_events/src/presentation/widgets/organizer_checkin/organizer_checkin_widgets.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'organizer_checkin_attendee_coordinator.dart';
part 'organizer_checkin_attendee_slivers.dart';
part 'organizer_checkin_confirm_sheet.dart';
part 'organizer_checkin_event_lifecycle.dart';

/// Organizer check-in screen: displays a QR code attendees scan.
part 'organizer_checkin_screen_state.dart';
part 'organizer_checkin_ws_coordinator.dart';

/// After each scan the QR regenerates. Checked-in names appear in the list.
class OrganizerCheckInScreen extends ConsumerStatefulWidget {
  const OrganizerCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<OrganizerCheckInScreen> createState() =>
      _OrganizerCheckInScreenState();
}

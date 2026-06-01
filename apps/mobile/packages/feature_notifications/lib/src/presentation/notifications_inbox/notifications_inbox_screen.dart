library;

import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/notification_inbox_router.dart';
import 'package:feature_notifications/src/data/notification_open_diagnostics.dart';
import 'package:feature_notifications/src/data/notifications_inbox_coordinator.dart';
import 'package:feature_notifications/src/domain/inbox_groups.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:feature_notifications/src/domain/notification_preference_groups.dart';
import 'package:feature_notifications/src/domain/notifications_time_format.dart';
import 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_list_controller.dart';
import 'package:feature_notifications/src/presentation/widgets/notifications_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'notifications_inbox_list_build.dart';
part 'notifications_inbox_preferences.dart';
part 'notifications_inbox_screen_state.dart';
part 'notifications_inbox_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.availableSites = const <PollutionSite>[],
  });

  final List<PollutionSite> availableSites;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

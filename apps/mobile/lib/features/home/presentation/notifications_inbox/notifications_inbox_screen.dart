library;

import 'dart:async';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/notifications/data/notifications_inbox_coordinator.dart';
import 'package:chisto_mobile/features/notifications/data/notifications_realtime_service.dart';
import 'package:chisto_mobile/features/notifications/data/notification_inbox_router.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';
import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:chisto_mobile/core/providers/notifications_providers.dart';
import 'package:chisto_mobile/features/notifications/domain/inbox_groups.dart';
import 'package:chisto_mobile/features/notifications/domain/notification_preference_groups.dart';
import 'package:chisto_mobile/features/notifications/domain/notifications_time_format.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_day_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_group_tile.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';

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


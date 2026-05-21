library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_mobile/core/cache/site_image_provider.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_inline_notice.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_boundaries_repository.dart';
import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_cluster_effective_zoom_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_cluster_expansion_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_clusters_provider.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_location_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_selection_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_ui_mode_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_actions_menu.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_canvas.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_error_overlay.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_filter_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_heatmap_layer.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_layout_tokens.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/animated_pollution_map_markers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_marker_entrance_cache.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_overlays.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_region_fence_builder.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_sheet_launcher.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_site_preview_positioned.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_sync_notice_banner.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_toolbar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/search_modal.dart';
import 'package:chisto_mobile/features/home/presentation/controllers/map_search_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/controllers/map_viewport_controller.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';

part 'pollution_map_screen_state.dart';

class PollutionMapScreen extends ConsumerStatefulWidget {
  const PollutionMapScreen({
    super.key,
    this.pendingSiteFocus,
    this.onPendingSiteFocusConsumed,
    this.isActive = true,
  });

  final ValueNotifier<String?>? pendingSiteFocus;
  final VoidCallback? onPendingSiteFocusConsumed;
  final bool isActive;

  @override
  ConsumerState<PollutionMapScreen> createState() => _PollutionMapScreenState();
}

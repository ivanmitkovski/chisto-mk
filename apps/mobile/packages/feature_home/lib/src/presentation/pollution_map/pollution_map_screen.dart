library;

import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_infrastructure/core/cache/site_image_provider.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_coordinator.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_inline_notice.dart';
import 'package:feature_home/src/data/map_regions/macedonia_map_regions.dart';
import 'package:feature_home/src/data/map_regions/map_boundaries_repository.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/controllers/map_search_coordinator.dart';
import 'package:feature_home/src/presentation/controllers/map_viewport_controller.dart';
import 'package:feature_home/src/presentation/location_permission_ui.dart';
import 'package:feature_home/src/presentation/pollution_map/map_clustering_camera_controller.dart';
import 'package:feature_home/src/presentation/pollution_map/map_updated_toast_gate.dart';
import 'package:feature_home/src/presentation/providers/map_camera_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_cluster_expansion_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_clusters_provider.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_location_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_marker_entrance_cache_provider.dart';
import 'package:feature_home/src/presentation/providers/map_selection_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_sites_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_ui_mode_notifier.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';
import 'package:feature_home/src/presentation/utils/map_animation_policy.dart';
import 'package:feature_home/src/presentation/utils/map_site_filter.dart';
import 'package:feature_home/src/presentation/utils/map_spiderfy.dart';
import 'package:feature_home/src/presentation/widgets/map/animated_pollution_map_markers.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:feature_home/src/presentation/widgets/map/map_actions_menu.dart';
import 'package:feature_home/src/presentation/widgets/map/map_canvas.dart';
import 'package:feature_home/src/presentation/widgets/map/map_error_overlay.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_sheet.dart';
import 'package:feature_home/src/presentation/widgets/map/map_heatmap_layer.dart';
import 'package:feature_home/src/presentation/widgets/map/map_layout_tokens.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_entrance_cache.dart';
import 'package:feature_home/src/presentation/widgets/map/map_overlays.dart';
import 'package:feature_home/src/presentation/widgets/map/map_region_fence_builder.dart';
import 'package:feature_home/src/presentation/widgets/map/map_sheet_launcher.dart';
import 'package:feature_home/src/presentation/widgets/map/map_site_preview_positioned.dart';
import 'package:feature_home/src/presentation/widgets/map/map_sync_notice_banner.dart';
import 'package:feature_home/src/presentation/widgets/map/map_toolbar.dart';
import 'package:feature_home/src/presentation/widgets/map/search_modal.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

part 'pollution_map_cluster_actions.dart';
part 'pollution_map_location_coordinator.dart';
part 'pollution_map_screen_state.dart';
part 'pollution_map_tile_overlay_coordinator.dart';

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

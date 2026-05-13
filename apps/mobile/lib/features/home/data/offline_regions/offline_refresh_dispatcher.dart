import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_downloader.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_model.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_store.dart';

/// Background refresh for saved offline map regions (unmetered network only).
///
/// Invoked from the unified [chistoWorkmanagerCallbackDispatcher] in
/// `lib/core/background/chisto_workmanager_dispatcher.dart`.
abstract final class OfflineRefreshDispatcher {
  static const String taskName = 'refreshSavedRegions';

  /// Re-downloads tiles + `/sites/map` JSON for every saved region.
  static Future<bool> runRefreshSavedRegions() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      final OfflineRegionStore store = OfflineRegionStore();
      await store.init();
      final List<OfflineRegion> regions = store.getRegions();
      if (regions.isEmpty) {
        return true;
      }
      final AppConfig config = AppConfig.fromEnvironment();
      final SecureTokenStorage tokenStorage = SecureTokenStorage();
      final String? token = await tokenStorage.accessToken;
      final ApiClient client = ApiClient(
        config: config,
        accessToken: () => token,
        onUnauthorized: () {},
      );
      final OfflineRegionDownloader downloader = OfflineRegionDownloader(
        apiClient: client,
        store: store,
      );
      for (final OfflineRegion region in regions) {
        await downloader.downloadRegion(region);
      }
      client.dispose();
      return true;
    } on Exception catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OfflineRefreshDispatcher] failed: $e\n$st');
      }
      return false;
    }
  }
}

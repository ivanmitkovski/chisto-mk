import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/cache/report_images_cache.dart';

/// Caps Flutter [ImageCache] and evicts disk report image cache on memory pressure.
class ImageCacheGovernor with WidgetsBindingObserver {
  ImageCacheGovernor._();

  static final ImageCacheGovernor instance = ImageCacheGovernor._();

  bool _installed = false;

  /// Call once after [WidgetsFlutterBinding.ensureInitialized].
  void install() {
    if (_installed) {
      return;
    }
    _installed = true;
    final ImageCache cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 200;
    cache.maximumSizeBytes = 96 << 20;
    WidgetsBinding.instance.addObserver(this);
  }

  void uninstall() {
    if (!_installed) {
      return;
    }
    _installed = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    unawaited(_evictReportImagesDiskBestEffort());
  }
}

Future<void> _evictReportImagesDiskBestEffort() async {
  try {
    await reportImagesCache.emptyCache();
  } catch (_) {
    // Best-effort; avoid rethrowing from observer.
  }
}

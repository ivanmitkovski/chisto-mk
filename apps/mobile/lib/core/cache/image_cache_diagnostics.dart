import 'package:flutter/foundation.dart';

class ImageCacheDiagnosticsSnapshot {
  const ImageCacheDiagnosticsSnapshot({
    required this.renderStarts,
    required this.renderSuccess,
    required this.renderErrors,
    required this.retryAttempts,
    required this.prefetchQueued,
    required this.prefetchSkipped,
    required this.cacheHits,
    required this.cacheMisses,
  });

  final int renderStarts;
  final int renderSuccess;
  final int renderErrors;
  final int retryAttempts;
  final int prefetchQueued;
  final int prefetchSkipped;
  final int cacheHits;
  final int cacheMisses;
}

class ImageCacheDiagnostics {
  static int _renderStarts = 0;
  static int _renderSuccess = 0;
  static int _renderErrors = 0;
  static int _retryAttempts = 0;
  static int _prefetchQueued = 0;
  static int _prefetchSkipped = 0;
  static int _cacheHits = 0;
  static int _cacheMisses = 0;

  static void recordRenderStart() => _renderStarts += 1;
  static void recordRenderSuccess() => _renderSuccess += 1;
  static void recordRenderError() => _renderErrors += 1;
  static void recordRetry() => _retryAttempts += 1;
  static void recordPrefetchQueued() => _prefetchQueued += 1;
  static void recordPrefetchSkipped() => _prefetchSkipped += 1;
  static void recordCacheHit() => _cacheHits += 1;
  static void recordCacheMiss() => _cacheMisses += 1;

  static ImageCacheDiagnosticsSnapshot snapshot() {
    return ImageCacheDiagnosticsSnapshot(
      renderStarts: _renderStarts,
      renderSuccess: _renderSuccess,
      renderErrors: _renderErrors,
      retryAttempts: _retryAttempts,
      prefetchQueued: _prefetchQueued,
      prefetchSkipped: _prefetchSkipped,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
    );
  }

  static String debugSummary() {
    final ImageCacheDiagnosticsSnapshot s = snapshot();
    return '[ImageCache] starts=${s.renderStarts} success=${s.renderSuccess} '
        'errors=${s.renderErrors} retries=${s.retryAttempts} '
        'prefetchQueued=${s.prefetchQueued} prefetchSkipped=${s.prefetchSkipped} '
        'hits=${s.cacheHits} misses=${s.cacheMisses}';
  }

  static void logDebugSummary({String reason = 'manual'}) {
    if (!kDebugMode) return;
    debugPrint('${debugSummary()} reason=$reason');
  }
}

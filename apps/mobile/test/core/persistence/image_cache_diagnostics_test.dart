import 'package:chisto_persistence/chisto_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageCacheDiagnostics', () {
    test('record methods increment snapshot counters', () {
      final ImageCacheDiagnosticsSnapshot before =
          ImageCacheDiagnostics.snapshot();

      ImageCacheDiagnostics.recordRenderStart();
      ImageCacheDiagnostics.recordRenderSuccess();
      ImageCacheDiagnostics.recordRenderError();
      ImageCacheDiagnostics.recordRetry();
      ImageCacheDiagnostics.recordPrefetchQueued();
      ImageCacheDiagnostics.recordPrefetchSkipped();
      ImageCacheDiagnostics.recordCacheHit();
      ImageCacheDiagnostics.recordCacheMiss();

      final ImageCacheDiagnosticsSnapshot after =
          ImageCacheDiagnostics.snapshot();
      expect(after.renderStarts, before.renderStarts + 1);
      expect(after.renderSuccess, before.renderSuccess + 1);
      expect(after.renderErrors, before.renderErrors + 1);
      expect(after.retryAttempts, before.retryAttempts + 1);
      expect(after.prefetchQueued, before.prefetchQueued + 1);
      expect(after.prefetchSkipped, before.prefetchSkipped + 1);
      expect(after.cacheHits, before.cacheHits + 1);
      expect(after.cacheMisses, before.cacheMisses + 1);
    });

    test('debugSummary includes all metric keys', () {
      final String summary = ImageCacheDiagnostics.debugSummary();
      expect(summary, startsWith('[ImageCache]'));
      expect(summary, contains('starts='));
      expect(summary, contains('success='));
      expect(summary, contains('errors='));
      expect(summary, contains('retries='));
      expect(summary, contains('prefetchQueued='));
      expect(summary, contains('prefetchSkipped='));
      expect(summary, contains('hits='));
      expect(summary, contains('misses='));
    });
  });
}

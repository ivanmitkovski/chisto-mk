import 'package:chisto_infrastructure/core/cache/report_image_provider.dart';
import 'package:chisto_infrastructure/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:flutter/material.dart';

/// Warms report evidence images for list and detail without blocking the UI thread
/// longer than chunked [precacheImage] work allows.
abstract class ReportImagePrefetchCoordinator {
  Future<void> warmList(List<ReportListItem> items, BuildContext context);

  Future<void> warmDetail(
    String reportId,
    List<String> evidence,
    BuildContext context,
  );

  void cancel();
}

class DefaultReportImagePrefetchCoordinator
    implements ReportImagePrefetchCoordinator {
  bool _cancelled = false;

  static const int _maxConcurrent = 4;

  @override
  void cancel() {
    _cancelled = true;
  }

  @override
  Future<void> warmList(
    List<ReportListItem> items,
    BuildContext context,
  ) async {
    _cancelled = false;
    if (!context.mounted) {
      return;
    }
    const int thumbDecode = 216;
    final int fullDecode = _decodeWidthCap(context);

    final List<Future<void> Function()> thumbs = <Future<void> Function()>[];
    for (final ReportListItem item in items) {
      if (item.mediaUrls.isEmpty) {
        continue;
      }
      final String first = item.mediaUrls.first;
      if (!_isHttp(first)) {
        continue;
      }
      thumbs.add(
        () => _precacheOne(
          context,
          imageProviderForReportEvidence(
            first,
            maxWidth: thumbDecode,
            maxHeight: thumbDecode,
          ),
        ),
      );
    }
    await _runInChunks(thumbs, context);
    if (!context.mounted) {
      return;
    }

    final List<Future<void> Function()> topThreeFull =
        <Future<void> Function()>[];
    for (int i = 0; i < items.length && i < 3; i++) {
      for (final String url in items[i].mediaUrls) {
        if (!_isHttp(url)) {
          continue;
        }
        topThreeFull.add(
          () => _precacheOne(
            context,
            imageProviderForReportEvidence(url, maxWidth: fullDecode),
          ),
        );
      }
    }
    await _runInChunks(topThreeFull, context);
    chistoReportsBreadcrumb(
      'reports_prefetch',
      'warmList finished',
      data: <String, Object?>{'rows': items.length},
    );
  }

  @override
  Future<void> warmDetail(
    String reportId,
    List<String> evidence,
    BuildContext context,
  ) async {
    _cancelled = false;
    if (!context.mounted) {
      return;
    }
    final int w = _decodeWidthCap(context);
    final List<Future<void> Function()> tasks = <Future<void> Function()>[];
    for (final String url in evidence) {
      if (!_isHttp(url)) {
        continue;
      }
      tasks.add(
        () => _precacheOne(
          context,
          imageProviderForReportEvidence(url, maxWidth: w),
        ),
      );
    }
    await _runInChunks(tasks, context);
    chistoReportsBreadcrumb(
      'reports_prefetch',
      'warmDetail finished',
      data: <String, Object?>{'reportId': reportId, 'urls': evidence.length},
    );
  }

  int _decodeWidthCap(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double px = mq.size.width * mq.devicePixelRatio;
    return px.clamp(1, 1280).round();
  }

  static bool _isHttp(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  Future<void> _precacheOne(
    BuildContext context,
    ImageProvider provider,
  ) async {
    if (_cancelled || !context.mounted) {
      return;
    }
    await safePrecacheImage(provider, context);
  }

  Future<void> _runInChunks(
    List<Future<void> Function()> work,
    BuildContext context,
  ) async {
    for (int i = 0; i < work.length; i += _maxConcurrent) {
      if (_cancelled || !context.mounted) {
        return;
      }
      final int end = i + _maxConcurrent > work.length
          ? work.length
          : i + _maxConcurrent;
      await Future.wait(<Future<void>>[
        for (int j = i; j < end; j++) work[j](),
      ]);
    }
  }
}

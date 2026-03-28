import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:chisto_mobile/core/cache/image_cache_diagnostics.dart';

class SiteImagePrefetchQueue {
  SiteImagePrefetchQueue._();

  static final SiteImagePrefetchQueue instance = SiteImagePrefetchQueue._();

  /// Slightly higher concurrency helps map pin warm-up on fast pans without flooding IO.
  static const int _maxConcurrent = 3;
  static const int _maxQueueSize = 24;
  static const int _recentCapacity = 120;

  final Queue<_PrefetchTask> _queue = Queue<_PrefetchTask>();
  final Set<String> _queuedKeys = <String>{};
  final Set<String> _inFlightKeys = <String>{};
  final Queue<String> _recentKeys = Queue<String>();
  final Set<String> _recentLookup = <String>{};
  int _active = 0;

  void prefetchList(
    BuildContext context,
    List<ImageProvider> images, {
    int maxItems = 3,
    bool Function()? shouldPrefetch,
  }) {
    for (int i = 0; i < images.length && i < maxItems; i++) {
      enqueue(context, images[i], shouldPrefetch: shouldPrefetch);
    }
  }

  void prefetchAround(
    BuildContext context,
    List<ImageProvider> images,
    int centerIndex, {
    bool Function()? shouldPrefetch,
  }) {
    final List<int> indexes = <int>[
      centerIndex + 1,
      centerIndex + 2,
      centerIndex - 1,
    ];
    for (final int idx in indexes) {
      if (idx < 0 || idx >= images.length) continue;
      enqueue(context, images[idx], shouldPrefetch: shouldPrefetch);
    }
  }

  void enqueue(
    BuildContext context,
    ImageProvider provider, {
    bool Function()? shouldPrefetch,
  }) {
    final String? key = _prefetchKey(provider);
    if (key == null) return;
    if (_recentLookup.contains(key) ||
        _inFlightKeys.contains(key) ||
        _queuedKeys.contains(key)) {
      ImageCacheDiagnostics.recordPrefetchSkipped();
      return;
    }
    if (_queue.length >= _maxQueueSize) {
      ImageCacheDiagnostics.recordPrefetchSkipped();
      return;
    }
    _queue.add(
      _PrefetchTask(
        imageConfiguration: createLocalImageConfiguration(context),
        provider: provider,
        key: key,
        shouldPrefetch: shouldPrefetch,
      ),
    );
    _queuedKeys.add(key);
    ImageCacheDiagnostics.recordPrefetchQueued();
    _drain();
  }

  void _drain() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final _PrefetchTask task = _queue.removeFirst();
      _queuedKeys.remove(task.key);
      if (task.shouldPrefetch != null && !task.shouldPrefetch!.call()) {
        ImageCacheDiagnostics.recordPrefetchSkipped();
        continue;
      }
      _active += 1;
      _run(task).whenComplete(() {
        _active = _active > 0 ? _active - 1 : 0;
        _drain();
      });
    }
  }

  ImageProvider _rootImageProvider(ImageProvider provider) {
    ImageProvider p = provider;
    while (p is ResizeImage) {
      p = p.imageProvider;
    }
    return p;
  }

  Future<void> _run(_PrefetchTask task) async {
    _inFlightKeys.add(task.key);
    try {
      if (_rootImageProvider(task.provider)
          case final CachedNetworkImageProvider provider) {
        final BaseCacheManager manager =
            provider.cacheManager ?? DefaultCacheManager();
        final String cacheKey = provider.cacheKey ?? provider.url;
        final FileInfo? cached = await manager.getFileFromCache(cacheKey);
        if (cached != null && cached.file.existsSync()) {
          ImageCacheDiagnostics.recordCacheHit();
          _remember(task.key);
          return;
        }
        ImageCacheDiagnostics.recordCacheMiss();
      }
      await _warmImage(task.provider, task.imageConfiguration);
      _remember(task.key);
    } catch (_) {
      ImageCacheDiagnostics.recordPrefetchSkipped();
    } finally {
      _inFlightKeys.remove(task.key);
    }
  }

  void _remember(String key) {
    if (_recentLookup.contains(key)) return;
    _recentKeys.addLast(key);
    _recentLookup.add(key);
    while (_recentKeys.length > _recentCapacity) {
      final String oldest = _recentKeys.removeFirst();
      _recentLookup.remove(oldest);
    }
  }

  Future<void> _warmImage(
    ImageProvider provider,
    ImageConfiguration configuration,
  ) async {
    final Completer<void> completer = Completer<void>();
    final ImageStream stream = provider.resolve(configuration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool syncCall) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(const Duration(seconds: 8));
  }

  String? _prefetchKey(ImageProvider provider) {
    if (_rootImageProvider(provider) case final CachedNetworkImageProvider p) {
      return p.cacheKey ?? p.url;
    }
    if (provider case final FileImage p) {
      return p.file.path;
    }
    if (provider case final NetworkImage p) {
      return p.url;
    }
    return provider.toString();
  }
}

class _PrefetchTask {
  const _PrefetchTask({
    required this.imageConfiguration,
    required this.provider,
    required this.key,
    required this.shouldPrefetch,
  });

  final ImageConfiguration imageConfiguration;
  final ImageProvider provider;
  final String key;
  final bool Function()? shouldPrefetch;
}

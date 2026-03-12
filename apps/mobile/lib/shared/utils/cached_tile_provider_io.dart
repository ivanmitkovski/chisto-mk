import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

TileProvider? createCachedTileProvider({int maxStaleDays = 30}) =>
    _CachedTileProvider(maxStaleDays: maxStaleDays);

/// Fallback offline tile caching for flutter_map (mobile only).
class _CachedTileProvider extends TileProvider {
  _CachedTileProvider({super.headers, this.maxStaleDays = 30}) {
    _warmCache();
  }

  final int maxStaleDays;
  String? _cacheDir;
  Future<String>? _cachePathFuture;

  Future<String> get _cachePath async {
    _cachePathFuture ??= _resolveCachePath();
    return _cachePathFuture!;
  }

  Future<String> _resolveCachePath() async {
    final String dir = (await getTemporaryDirectory())
        .path
        .replaceAll('/', Platform.pathSeparator);
    _cacheDir ??= dir;
    return '$_cacheDir${Platform.pathSeparator}map_tiles';
  }

  void _warmCache() {
    getTemporaryDirectory().then((Directory d) async {
      final String tileDir =
          '${d.path.replaceAll('/', Platform.pathSeparator)}${Platform.pathSeparator}map_tiles';
      final Directory dir = Directory(tileDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    });
  }

  Future<File> _cacheFile(String url) async {
    final String dir = await _cachePath;
    final String key = '${url.hashCode & 0x7fffffff}.png';
    return File('$dir${Platform.pathSeparator}$key');
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final String url = getTileUrl(coordinates, options);
    return _CachedTileImageProvider(
      url: url,
      cacheFile: _cacheFile(url),
      headers: headers,
      maxStaleDays: maxStaleDays,
    );
  }
}

class _CachedTileImageProvider
    extends ImageProvider<_CachedTileImageProvider> {
  _CachedTileImageProvider({
    required this.url,
    required this.cacheFile,
    this.headers,
    this.maxStaleDays = 30,
  });

  final String url;
  final Future<File> cacheFile;
  final Map<String, String>? headers;
  final int maxStaleDays;

  @override
  Future<_CachedTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _loadAsync(decode),
        scale: 1.0,
        debugLabel: url,
      );

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final File file = await cacheFile;
    final String dir = file.parent.path;
    if (!await Directory(dir).exists()) {
      await Directory(dir).create(recursive: true);
    }

    if (await file.exists()) {
      final DateTime mod = await file.lastModified();
      final bool stale =
          DateTime.now().difference(mod).inDays > maxStaleDays;
      if (!stale) {
        try {
          final Uint8List bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            final ui.ImmutableBuffer buffer =
                await ui.ImmutableBuffer.fromUint8List(bytes);
            return decode(buffer);
          }
        } catch (_) {}
      }
    }

    try {
      final http.Response response = await http
          .get(Uri.parse(url), headers: headers ?? <String, String>{})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        final ui.ImmutableBuffer buffer =
            await ui.ImmutableBuffer.fromUint8List(response.bodyBytes);
        return decode(buffer);
      }
    } catch (_) {}

    if (await file.exists()) {
      try {
        final Uint8List fallbackBytes = await file.readAsBytes();
        if (fallbackBytes.isNotEmpty) {
          final ui.ImmutableBuffer buffer =
              await ui.ImmutableBuffer.fromUint8List(fallbackBytes);
          return decode(buffer);
        }
      } catch (_) {}
    }

    throw StateError('Tile load failed: $url');
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

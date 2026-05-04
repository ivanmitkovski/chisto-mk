import 'dart:io';
import 'dart:math';

import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of [ReportDraftPhotoStore.clearAll] (best-effort; callers may log [failedPaths]).
class ReportDraftPhotoClearResult {
  const ReportDraftPhotoClearResult({
    required this.deletedCount,
    required this.failedPaths,
  });

  final int deletedCount;
  final List<String> failedPaths;

  bool get hasFailures => failedPaths.isNotEmpty;
}

/// Persists wizard draft photos under app documents so paths survive OS temp eviction.
class ReportDraftPhotoStore {
  ReportDraftPhotoStore({Directory? rootOverride}) : _rootOverride = rootOverride;

  final Directory? _rootOverride;

  /// Relative to [getApplicationDocumentsDirectory] (single segment + filename).
  static const String relativeRoot = 'report_draft_media';

  static const String _tmpDirName = '.tmp';

  Future<Directory> _rootDir() async {
    if (_rootOverride != null) {
      final Directory o = _rootOverride!;
      if (!await o.exists()) {
        await o.create(recursive: true);
      }
      return o;
    }
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory root = Directory(p.join(docs.path, relativeRoot));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<Directory> _tmpDir(Directory root) async {
    final Directory d = Directory(p.join(root.path, _tmpDirName));
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  /// Absolute path for a stored relative key (e.g. `report_draft_media/foo.jpg`).
  ///
  /// Files always live under [_rootDir]; the persisted key uses [relativeRoot] as
  /// a logical prefix so rows stay portable across app versions.
  Future<String> absolutePath(String relativePath) async {
    if (p.isAbsolute(relativePath)) {
      return p.normalize(relativePath);
    }
    final Directory root = await _rootDir();
    final String norm = p.normalize(relativePath);
    final String fileName = norm.startsWith('$relativeRoot${p.separator}')
        ? norm.substring(relativeRoot.length + 1)
        : norm;
    return p.normalize(p.join(root.path, p.basename(fileName)));
  }

  /// Copies [src] into the managed folder via a temp file + rename (atomic on same FS).
  /// Returns path relative to app documents.
  Future<String> importPhoto(XFile src) async {
    final Directory root = await _rootDir();
    final Directory tmp = await _tmpDir(root);
    final String baseName = p.basename(src.path);
    final String ext =
        p.extension(baseName).isNotEmpty ? p.extension(baseName) : '.jpg';
    final String name =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 30)}$ext';
    final String tmpPath = p.join(tmp.path, name);
    final String finalPath = p.join(root.path, name);
    await File(src.path).copy(tmpPath);
    await File(tmpPath).rename(finalPath);
    return p.join(relativeRoot, name);
  }

  /// Best-effort delete of one stored file (relative or absolute under managed root).
  Future<void> deletePhoto(String relativeOrAbsolute) async {
    try {
      final String path = p.isAbsolute(relativeOrAbsolute)
          ? relativeOrAbsolute
          : await absolutePath(relativeOrAbsolute);
      final File f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      chistoReportsBreadcrumb(
        'report_draft',
        'delete_photo_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
    }
  }

  /// Drops paths whose files are missing; returns kept relative paths.
  Future<List<String>> prune(List<String> relativePaths) async {
    final List<String> kept = <String>[];
    for (final String rel in relativePaths) {
      if (rel.isEmpty) continue;
      final String abs = await absolutePath(rel);
      if (await File(abs).exists()) {
        kept.add(rel);
      }
    }
    return kept;
  }

  /// Deletes all files under the managed folder (submit success / discard draft).
  Future<ReportDraftPhotoClearResult> clearAll() async {
    final Directory root = await _rootDir();
    if (!await root.exists()) {
      return const ReportDraftPhotoClearResult(
        deletedCount: 0,
        failedPaths: <String>[],
      );
    }
    int deleted = 0;
    final List<String> failed = <String>[];
    await for (final FileSystemEntity e in root.list()) {
      if (e is Directory && p.basename(e.path) == _tmpDirName) {
        await for (final FileSystemEntity t in e.list()) {
          if (t is File) {
            try {
              await t.delete();
              deleted++;
            } catch (_) {
              failed.add(t.path);
            }
          }
        }
        try {
          await e.delete(recursive: true);
        } catch (_) {
          failed.add(e.path);
        }
        continue;
      }
      if (e is File) {
        try {
          await e.delete();
          deleted++;
        } catch (_) {
          failed.add(e.path);
        }
      }
    }
    if (failed.isNotEmpty) {
      chistoReportsBreadcrumb(
        'report_draft',
        'photo_orphan',
        data: <String, Object?>{'failedCount': failed.length},
      );
    }
    return ReportDraftPhotoClearResult(
      deletedCount: deleted,
      failedPaths: failed,
    );
  }

  /// Whether [path] points into the managed directory.
  Future<bool> isManagedPath(String path) async {
    final String abs = p.normalize(
      p.isAbsolute(path) ? path : await absolutePath(path),
    );
    final Directory root = await _rootDir();
    final String rootPath = p.normalize(root.path);
    return abs.startsWith(rootPath);
  }
}

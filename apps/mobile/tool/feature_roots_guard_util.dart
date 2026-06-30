import 'dart:io';

/// Legacy app-shell feature root (removed; features live in Melos packages).
const String appFeatureRoot = 'lib/features';

/// Shared presentation widgets extracted to infrastructure.
const String sharedWidgetsRoot =
    'packages/chisto_infrastructure/lib/shared/widgets';
const String l10nRoot = 'packages/chisto_localization/lib/l10n';
const String reportsPackageRoot = 'packages/feature_reports/lib';

/// Public barrel file name for a Melos feature package (e.g. `feature_home.dart`).
String featurePackageBarrel(String packageName) => '$packageName.dart';

/// All `packages/feature_*/lib` roots that exist on disk.
List<String> discoverFeaturePackageLibRoots() {
  final Directory packagesDir = Directory('packages');
  if (!packagesDir.existsSync()) {
    return <String>[];
  }
  final List<String> roots = <String>[];
  for (final FileSystemEntity entity in packagesDir.listSync()) {
    if (entity is! Directory) {
      continue;
    }
    final String name = entity.uri.pathSegments
        .where((String s) => s.isNotEmpty)
        .last;
    if (!name.startsWith('feature_')) {
      continue;
    }
    final Directory libDir = Directory('${entity.path}/lib');
    if (libDir.existsSync()) {
      roots.add(libDir.path.replaceAll(r'\', '/'));
    }
  }
  roots.sort();
  return roots;
}

/// Melos feature packages (sorted).
List<String> allFeatureLibRoots() {
  return discoverFeaturePackageLibRoots();
}

/// Feature packages plus shared widgets for design guards.
List<String> allFeatureAndSharedRoots() {
  return <String>[...allFeatureLibRoots(), sharedWidgetsRoot];
}

/// All Dart code roots under the mobile app (lib + workspace packages).
List<String> allAppCodeRoots() {
  final List<String> roots = <String>['lib'];
  final Directory packagesDir = Directory('packages');
  if (packagesDir.existsSync()) {
    for (final FileSystemEntity entity in packagesDir.listSync()) {
      if (entity is! Directory) {
        continue;
      }
      final Directory libDir = Directory('${entity.path}/lib');
      if (libDir.existsSync()) {
        roots.add(libDir.path.replaceAll(r'\', '/'));
      }
    }
  }
  roots.sort();
  return roots;
}

String normalizePath(String path) => path.replaceAll(r'\', '/');

/// Owner feature slug from an app-shell path (`lib/features/home/...` → `home`).
String? appFeatureOwner(String normalizedPath) {
  final List<String> parts = normalizedPath.split('/');
  final int featuresIdx = parts.indexOf('features');
  if (featuresIdx < 0 || featuresIdx + 1 >= parts.length) {
    return null;
  }
  return parts[featuresIdx + 1];
}

/// Owner package name from a package path (`packages/feature_home/lib/...` → `feature_home`).
String? packageFeatureOwner(String normalizedPath) {
  final List<String> parts = normalizedPath.split('/');
  final int packagesIdx = parts.indexOf('packages');
  if (packagesIdx < 0 || packagesIdx + 1 >= parts.length) {
    return null;
  }
  final String name = parts[packagesIdx + 1];
  return name.startsWith('feature_') ? name : null;
}

bool isPresentationPath(String normalizedPath) {
  return normalizedPath.contains('/presentation/') ||
      normalizedPath.contains('/src/presentation/');
}

bool isDomainPath(String normalizedPath) {
  return normalizedPath.contains('/domain/') ||
      normalizedPath.contains('/src/domain/');
}

bool isDataPath(String normalizedPath) {
  return normalizedPath.contains('/data/') ||
      normalizedPath.contains('/src/data/');
}

bool isApplicationPath(String normalizedPath) {
  return normalizedPath.contains('/application/') ||
      normalizedPath.contains('/src/application/');
}

bool isFeatureLayerPath(String normalizedPath) {
  return isPresentationPath(normalizedPath) ||
      isDataPath(normalizedPath) ||
      isApplicationPath(normalizedPath) ||
      isDomainPath(normalizedPath);
}

/// Iterate `.dart` files under [roots], optionally filtered by [pathMustContain].
Iterable<File> iterFeatureDartFiles({
  required List<String> roots,
  List<String> pathMustContain = const <String>[],
  List<String> skipPathFragments = const <String>[],
}) sync* {
  for (final String rootPath in roots) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String normalized = normalizePath(entity.path);
      if (pathMustContain.isNotEmpty &&
          !pathMustContain.any(normalized.contains)) {
        continue;
      }
      if (skipPathFragments.any(normalized.contains)) {
        continue;
      }
      yield entity;
    }
  }
}

List<String> scanFeatureLayerFiles({
  required bool Function(String normalizedPath) includeFile,
  required bool Function(String line) matchesLine,
  List<String> roots = const <String>[],
  List<String> skipPathFragments = const <String>[],
}) {
  final List<String> effectiveRoots = roots.isEmpty
      ? allFeatureLibRoots()
      : roots;
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(
    roots: effectiveRoots,
    skipPathFragments: skipPathFragments,
  )) {
    final String normalized = normalizePath(file.path);
    if (!includeFile(normalized)) {
      continue;
    }
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (matchesLine(lines[i])) {
        hits.add('$normalized:${i + 1}');
      }
    }
  }
  return hits;
}

/// Rewrites legacy `lib/features/reports/` allowlist paths to the package tree.
List<String> migrateReportsAllowlistPaths(List<String> entries) {
  return entries
      .map(
        (String entry) => entry.replaceFirst(
          'lib/features/reports/',
          'packages/feature_reports/lib/src/',
        ),
      )
      .toList();
}

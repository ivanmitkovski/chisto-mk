// Usage: dart run tool/check_cross_feature_imports.dart [--stamp-baseline]
//
// Feature modules must not import sibling features directly (use public barrels later).
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/cross_feature_import_allowlist.txt';

String appFeatureBarrel(String slug) => '$slug/$slug.dart';

List<String> collectCrossFeatureImportHits() {
  final RegExp appImportRe = RegExp(
    r"import\s+'package:chisto_mobile/features/(\w+)/([^']+)';",
  );
  // No trailing `;` so multi-line imports with `show`/`hide` clauses
  // (path on one line, `;` on the next) are also caught.
  final RegExp packageImportRe = RegExp(
    r"import\s+'package:(feature_\w+)/([^']+)'",
  );
  const Map<String, String> slugToPackage = <String, String>{
    'auth': 'feature_auth',
    'home': 'feature_home',
    'events': 'feature_events',
    'reports': 'feature_reports',
    'profile': 'feature_profile',
    'notifications': 'feature_notifications',
    'onboarding': 'feature_onboarding',
    'safety': 'feature_safety',
  };
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    if (!isFeatureLayerPath(normalized)) {
      continue;
    }
    final String? appOwner = appFeatureOwner(normalized);
    final String? packageOwner = packageFeatureOwner(normalized);
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final RegExpMatch? match = appImportRe.firstMatch(lines[i]);
      if (match != null) {
        final String target = match.group(1)!;
        final String importSuffix = match.group(2)!;
        if (target == appOwner && importSuffix == appFeatureBarrel(target)) {
          continue;
        }
        if (appOwner != null && target != appOwner) {
          hits.add('$normalized:${i + 1}');
          continue;
        }
        if (packageOwner != null) {
          final String? targetPackage = slugToPackage[target];
          if (targetPackage != null &&
              targetPackage != packageOwner &&
              importSuffix != appFeatureBarrel(target)) {
            hits.add('$normalized:${i + 1}');
          }
        }
        continue;
      }
      final RegExpMatch? pkgMatch = packageImportRe.firstMatch(lines[i]);
      if (pkgMatch == null || packageOwner == null) {
        continue;
      }
      final String targetPackage = pkgMatch.group(1)!;
      final String importSuffix = pkgMatch.group(2)!;
      if (!targetPackage.startsWith('feature_') ||
          targetPackage == packageOwner) {
        continue;
      }
      if (importSuffix == featurePackageBarrel(targetPackage)) {
        continue;
      }
      hits.add('$normalized:${i + 1}');
    }
  }
  return hits;
}

int runCrossFeatureImportCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Cross-feature import',
    hits: collectCrossFeatureImportHits(),
    allowlistPath: _allowlistPath,
    fixHint:
        'Expose shared APIs via chisto_core/design_system or a feature public barrel; '
        'do not deep-import sibling features.',
  );
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: collectCrossFeatureImportHits(),
    );
    exit(0);
  }
  exit(runCrossFeatureImportCheck());
}

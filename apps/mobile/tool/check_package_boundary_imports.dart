// Usage: dart run tool/check_package_boundary_imports.dart [--stamp-baseline]
//
// Feature packages must depend on sibling features via public barrels only.
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/package_boundary_import_allowlist.txt';

List<String> collectPackageBoundaryImportHits() {
  // No trailing `;` so multi-line imports with `show`/`hide` clauses
  // (path on one line, `;` on the next) are also caught.
  final RegExp featureImport = RegExp(
    r"import\s+'package:(feature_\w+)/([^']+)'",
  );
  final List<String> hits = <String>[];
  for (final String root in discoverFeaturePackageLibRoots()) {
    for (final File file in iterFeatureDartFiles(roots: <String>[root])) {
      final String normalized = normalizePath(file.path);
      final String? owner = packageFeatureOwner(normalized);
      if (owner == null) {
        continue;
      }
      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final RegExpMatch? match = featureImport.firstMatch(lines[i]);
        if (match == null) {
          continue;
        }
        final String targetPackage = match.group(1)!;
        final String importSuffix = match.group(2)!;
        if (targetPackage == owner) {
          continue;
        }
        if (importSuffix == featurePackageBarrel(targetPackage)) {
          continue;
        }
        hits.add('$normalized:${i + 1}');
      }
    }
  }
  return hits;
}

int runPackageBoundaryImportCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Feature package deep import',
    hits: collectPackageBoundaryImportHits(),
    allowlistPath: _allowlistPath,
    fixHint:
        'Import sibling features via `package:feature_x/feature_x.dart` barrels '
        'or shared `chisto_*` / `design_system` packages — no deep `src/` imports.',
  );
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: collectPackageBoundaryImportHits(),
    );
    exit(0);
  }
  exit(runPackageBoundaryImportCheck());
}

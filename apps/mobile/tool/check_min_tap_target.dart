// ignore_for_file: avoid_print

import 'dart:io';

import 'feature_roots_guard_util.dart';

/// Heuristic: flags interactive widgets with a fixed [height] or [width] under
/// 44dp inside feature code. Material guideline is 48dp; we use 44 as a
/// floor because Cupertino uses 44pt. Allow-listed because dense rows
/// legitimately exist for compact toolbars — those should add explicit
/// [Semantics] containers; future passes can tighten this.
///
/// Conservative parser: only catches the patterns we know are widespread
/// (`GestureDetector(onTap: ...)`, `InkWell`, `IconButton`) wrapping a
/// `SizedBox(width: N, height: N)` where N is a literal under 44.
int runMinTapTargetCheck() {
  final RegExp tapWrapper = RegExp(
    r'(GestureDetector|InkWell|IconButton)\s*\(',
  );
  final RegExp sizedBoxSize = RegExp(
    r'SizedBox\s*\(\s*width:\s*(\d+(?:\.\d+)?)[^,)]*,\s*height:\s*(\d+(?:\.\d+)?)',
  );
  final List<String> violations = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    final String src = file.readAsStringSync();
    if (!tapWrapper.hasMatch(src)) continue;
    final Iterable<RegExpMatch> hits = sizedBoxSize.allMatches(src);
    for (final RegExpMatch m in hits) {
      final double w = double.tryParse(m.group(1)!) ?? 99;
      final double h = double.tryParse(m.group(2)!) ?? 99;
      // Heuristic: only flag SizedBox sizes that are paired with a tap
      // wrapper within ~120 chars before the SizedBox.
      final int idx = m.start;
      final int from = idx > 200 ? idx - 200 : 0;
      final String prefix = src.substring(from, idx);
      if (!tapWrapper.hasMatch(prefix)) continue;
      if (w < 44 || h < 44) {
        violations.add(
          '$normalized: tap target ${w.toInt()}×${h.toInt()}dp at offset $idx',
        );
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Sub-44dp tap targets found in features (raise to ≥48dp or add Semantics container):\n'
      '${violations.take(40).join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: no obvious sub-44dp tap targets in features.');
  return 0;
}

void main() {
  exit(runMinTapTargetCheck());
}

// Usage: dart run tool/check_no_flutter_in_domain.dart [--stamp-baseline]
//
// Domain layers must stay Flutter-free. Ratchets down over time via allowlist.
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/flutter_in_domain_allowlist.txt';

List<String> collectFlutterInDomainHits() {
  final RegExp flutterImport = RegExp(r"import\s+'package:flutter/");
  return scanFeatureLayerFiles(
    includeFile: isDomainPath,
    matchesLine: flutterImport.hasMatch,
  );
}

int runNoFlutterInDomainCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Flutter import in domain/',
    hits: collectFlutterInDomainHits(),
    allowlistPath: _allowlistPath,
    fixHint:
        'Move UI types out of domain/ or depend on pure-Dart abstractions in chisto_core.',
  );
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: collectFlutterInDomainHits(),
    );
    exit(0);
  }
  exit(runNoFlutterInDomainCheck());
}

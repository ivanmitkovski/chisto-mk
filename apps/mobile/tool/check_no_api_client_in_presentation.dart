// Usage: dart run tool/check_no_api_client_in_presentation.dart [--stamp-baseline]
//
// Presentation must talk to repositories/use-cases, not ApiClient directly.
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/api_client_in_presentation_allowlist.txt';

List<String> collectApiClientInPresentationHits() {
  final RegExp apiClientImport = RegExp(
    r"import\s+'package:chisto_mobile/core/network/api_client\.dart'",
  );
  final RegExp apiClientType = RegExp(r'\bApiClient\b');
  return scanFeatureLayerFiles(
    includeFile: isPresentationPath,
    matchesLine: (String line) {
      if (line.trim().startsWith('//')) {
        return false;
      }
      return apiClientImport.hasMatch(line) || apiClientType.hasMatch(line);
    },
  );
}

int runNoApiClientInPresentationCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'ApiClient in presentation/',
    hits: collectApiClientInPresentationHits(),
    allowlistPath: _allowlistPath,
    fixHint:
        'Inject a repository or use-case; presentation must not import ApiClient.',
  );
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: collectApiClientInPresentationHits(),
    );
    exit(0);
  }
  exit(runNoApiClientInPresentationCheck());
}

// ignore_for_file: avoid_print
/// CI guard: release builds reject the dev ENV family and enforce HTTPS API
/// transport. Beta (staging) and store (prod) release targets are allowed.
library;

import 'dart:io';

void main() {
  final File mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(1);
  }
  final String mainContent = mainFile.readAsStringSync();
  if (!mainContent.contains('kReleaseMode') ||
      !mainContent.contains('isReleaseEligible') ||
      !mainContent.contains('dart-define=ENV=staging') ||
      !mainContent.contains('dart-define=ENV=prod')) {
    stderr.writeln(
      'check_release_env: lib/main.dart must reject the dev ENV family in '
      'kReleaseMode and allow only staging/prod',
    );
    exit(1);
  }
  if (!mainContent.contains('assertReleaseTransportSecurity')) {
    stderr.writeln(
      'check_release_env: lib/main.dart must call AppConfig.assertReleaseTransportSecurity in kReleaseMode',
    );
    exit(1);
  }

  final File appConfig = File(
    'packages/chisto_infrastructure/lib/core/config/app_config.dart',
  );
  if (!appConfig.existsSync()) {
    stderr.writeln(
      'check_release_env: missing packages/chisto_infrastructure/lib/core/config/app_config.dart',
    );
    exit(1);
  }
  final String configContent = appConfig.readAsStringSync();
  if (!configContent.contains('assertReleaseTransportSecurity') ||
      !configContent.contains('.elb.amazonaws.com')) {
    stderr.writeln(
      'check_release_env: app_config.dart must reject non-HTTPS and ELB API URLs',
    );
    exit(1);
  }

  print('check_release_env: OK');
}

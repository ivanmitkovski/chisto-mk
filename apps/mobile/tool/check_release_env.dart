// ignore_for_file: avoid_print
/// CI guard: [main.dart] must enforce ENV=prod on release builds.
import 'dart:io';

void main() {
  final File main = File('lib/main.dart');
  if (!main.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(1);
  }
  final String content = main.readAsStringSync();
  if (!content.contains('kReleaseMode') ||
      !content.contains('config.isProd') ||
      !content.contains('dart-define=ENV=prod')) {
    stderr.writeln(
      'check_release_env: lib/main.dart must enforce ENV=prod in kReleaseMode',
    );
    exit(1);
  }
  print('check_release_env: OK');
}

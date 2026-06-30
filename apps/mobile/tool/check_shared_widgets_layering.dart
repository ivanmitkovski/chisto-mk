// Run from apps/mobile: dart run tool/check_shared_widgets_layering.dart
import 'dart:io';

const List<String> _allowedTopLevel = <String>[
  'atoms',
  'molecules',
  'organisms',
  'widgets.dart',
];

const String _sharedWidgetsRoot =
    'packages/chisto_infrastructure/lib/shared/widgets';

/// Returns `0` when clean, `1` when violations found.
int runSharedWidgetsLayeringCheck() {
  final Directory root = Directory(_sharedWidgetsRoot);
  if (!root.existsSync()) {
    stderr.writeln('Missing $_sharedWidgetsRoot');
    return 1;
  }
  final List<String> violations = <String>[];
  for (final FileSystemEntity entity in root.listSync()) {
    final String name = entity.uri.pathSegments.last;
    if (name.startsWith('.')) continue;
    if (_allowedTopLevel.contains(name)) continue;
    if (entity is File && name.endsWith('.dart')) {
      violations.add(entity.path);
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Shared widgets must live under atoms/, molecules/, or organisms/:\n'
      '${violations.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: shared/widgets layering (atoms/molecules/organisms).');
  return 0;
}

void main() {
  exit(runSharedWidgetsLayeringCheck());
}

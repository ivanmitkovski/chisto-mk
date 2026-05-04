// Run from apps/mobile: dart run tool/check_reports_widget_size.dart
import 'dart:io';

const int _maxScreenLines = 350;
const int _maxSectionLines = 200;

int _lineCount(File f) => f.readAsLinesSync().length;

int runWidgetSizeCheck() {
  final Directory root = Directory.current;
  final List<String> violations = <String>[];

  final File screen = File(
    '${root.path}/lib/features/reports/presentation/screens/new_report_screen.dart',
  );
  if (screen.existsSync()) {
    final int n = _lineCount(screen);
    if (n > _maxScreenLines) {
      violations.add(
        'new_report_screen.dart has $n lines (max $_maxScreenLines)',
      );
    }
  }

  final Directory widgetsDir = Directory(
    '${root.path}/lib/features/reports/presentation/widgets/new_report',
  );
  if (widgetsDir.existsSync()) {
    for (final FileSystemEntity e in widgetsDir.listSync(recursive: false)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String name = e.uri.pathSegments.last;
      if (!name.startsWith('new_report_') || !name.endsWith('_stage_body.dart')) {
        continue;
      }
      final int n = _lineCount(e);
      if (n > _maxSectionLines) {
        violations.add('$name has $n lines (max $_maxSectionLines)');
      }
    }
    final File details = File(
      '${widgetsDir.path}/new_report_details_form_fields.dart',
    );
    if (details.existsSync()) {
      final int n = _lineCount(details);
      if (n > _maxSectionLines) {
        violations.add(
          'new_report_details_form_fields.dart has $n lines (max $_maxSectionLines)',
        );
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Widget size guard failed:\n${violations.join('\n')}');
    return 1;
  }
  stdout.writeln('OK: reports widget size limits.');
  return 0;
}

void main() {
  exit(runWidgetSizeCheck());
}

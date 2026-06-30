// ignore_for_file: avoid_print
/// Play policy guard: merged release manifest must not declare broad photo/video
/// storage permissions (READ_MEDIA_* / READ_EXTERNAL_STORAGE). open_filex merges
/// them transitively; the app manifest strips them via tools:node="remove".
library;

import 'dart:io';

const String _appManifestPath = 'android/app/src/main/AndroidManifest.xml';

const List<String> _requiredRemoveDirectives = <String>[
  'android.permission.READ_MEDIA_IMAGES',
  'android.permission.READ_MEDIA_VIDEO',
];

const List<String> _forbiddenMergedPermissions = <String>[
  'android.permission.READ_MEDIA_IMAGES',
  'android.permission.READ_MEDIA_VIDEO',
  'android.permission.READ_MEDIA_AUDIO',
  'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
  'android.permission.READ_EXTERNAL_STORAGE',
];

void main() {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(1);
  }

  final Map<String, String> env = _gradleEnvironment();

  _assertAppManifestStripsPermissions();

  final ProcessResult gradle = Process.runSync(
    './gradlew',
    <String>[':app:processReleaseMainManifest', '--rerun-tasks', '--quiet'],
    workingDirectory: 'android',
    runInShell: true,
    environment: env,
  );
  if (gradle.exitCode != 0) {
    stderr.writeln(
      'check_android_play_media_permissions: gradle processReleaseMainManifest failed',
    );
    stderr.writeln(gradle.stderr);
    stderr.writeln(gradle.stdout);
    exit(1);
  }

  final File? merged = _findMergedReleaseManifest();
  if (merged == null) {
    stderr.writeln(
      'check_android_play_media_permissions: merged release manifest not found under build/',
    );
    exit(1);
  }

  final String mergedContent = merged.readAsStringSync();
  final List<String> found = <String>[];
  for (final String permission in _forbiddenMergedPermissions) {
    if (mergedContent.contains(permission)) {
      found.add(permission);
    }
  }
  if (found.isNotEmpty) {
    stderr.writeln(
      'check_android_play_media_permissions: forbidden permissions in merged manifest:',
    );
    for (final String permission in found) {
      stderr.writeln('  - $permission');
    }
    stderr.writeln('Merged manifest: ${merged.path}');
    exit(1);
  }

  print(
    'check_android_play_media_permissions: OK (${merged.path} has no forbidden media permissions)',
  );
}

void _assertAppManifestStripsPermissions() {
  final File manifest = File(_appManifestPath);
  if (!manifest.existsSync()) {
    stderr.writeln(
      'check_android_play_media_permissions: missing $_appManifestPath',
    );
    exit(1);
  }
  final String content = manifest.readAsStringSync();
  for (final String permission in _requiredRemoveDirectives) {
    final RegExp stripDirective = RegExp(
      'android:name="${RegExp.escape(permission)}"[^>]*tools:node="remove"',
    );
    if (!stripDirective.hasMatch(content)) {
      stderr.writeln(
        'check_android_play_media_permissions: $_appManifestPath must strip '
        '$permission with tools:node="remove"',
      );
      exit(1);
    }
  }
}

File? _findMergedReleaseManifest() {
  final Directory root = Directory('build/app/intermediates/merged_manifests');
  if (!root.existsSync()) {
    return null;
  }
  File? newest;
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File ||
        entity.path.endsWith('AndroidManifest.xml') != true) {
      continue;
    }
    if (!entity.path.contains('release')) {
      continue;
    }
    if (newest == null ||
        entity.lastModifiedSync().isAfter(newest.lastModifiedSync())) {
      newest = entity;
    }
  }
  return newest;
}

Map<String, String> _gradleEnvironment() {
  final Map<String, String> env = Map<String, String>.from(
    Platform.environment,
  );
  if (env.containsKey('JAVA_HOME')) {
    return env;
  }
  const List<String> candidates = <String>[
    '/Applications/Android Studio.app/Contents/jbr/Contents/Home',
    '/Applications/Android Studio.app/Contents/jre/Contents/Home',
  ];
  for (final String candidate in candidates) {
    if (File('$candidate/bin/java').existsSync()) {
      env['JAVA_HOME'] = candidate;
      return env;
    }
  }
  return env;
}

import 'dart:io' show File;

bool fileExistsSync(String path) => File(path).existsSync();

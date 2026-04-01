import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Normalizes paths from picker or temp files.
String resolvedPathForCrop(String path) {
  String p = path.trim();
  if (p.startsWith('file://')) {
    p = Uri.parse(p).toFilePath();
  }
  return File(p).absolute.path;
}

/// Copies the picker result into app temp so downstream code always sees a
/// normal file path.
Future<String> materializePickForNativeCrop(XFile file) async {
  final Directory tempDir = await getTemporaryDirectory();
  final String target =
      '${tempDir.path}/avatar_crop_in_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await file.saveTo(target);
  return File(target).absolute.path;
}

/// Brief settle after UIImagePicker / PHPicker before file work (kept short;
/// [SchedulerBinding.endOfFrame] handles most iOS teardown).
Future<void> waitAfterProfileAvatarPicker() async {
  if (Platform.isIOS) {
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await SchedulerBinding.instance.endOfFrame;
  } else {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await SchedulerBinding.instance.endOfFrame;
  }
}

/// Upper bound for decode width passed to [loadAvatarImageBytesForCrop].
const int kAvatarCropDecodeWidthMax = 1920;

/// Decodes image from disk and downscales so the crop UI stays responsive and
/// memory-safe. Output is PNG bytes for [Crop] in `crop_your_image`.
///
/// [maxDecodeWidth] should reflect screen density (see crop screen); clamped
/// internally so decode stays fast on large gallery originals.
Future<Uint8List?> loadAvatarImageBytesForCrop(
  String path, {
  int maxDecodeWidth = 1536,
}) async {
  try {
    final String absolute = resolvedPathForCrop(path);
    if (!File(absolute).existsSync()) return null;
    final int targetW = maxDecodeWidth.clamp(1024, kAvatarCropDecodeWidthMax);
    final Uint8List raw = await File(absolute).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(
      raw,
      targetWidth: targetW,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    final ByteData? png =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) return null;
    return png.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// JPEG compress and cap size (square targets [minWidth]/[minHeight]).
Future<File?> compressForAvatarUpload(File file) async {
  final Directory tempDir = await getTemporaryDirectory();
  final String targetPath =
      '${tempDir.path}/avatar_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final XFile? out = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 85,
    minWidth: 2048,
    minHeight: 2048,
    format: CompressFormat.jpeg,
  );
  if (out == null) return null;
  return File(out.path);
}

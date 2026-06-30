import 'dart:typed_data';

import 'package:mime/mime.dart';

/// MIME types accepted by [event-chat-upload.service.ts] on the API.
abstract final class ChatAttachmentMime {
  ChatAttachmentMime._();

  static String infer(String fileName, Uint8List bytes) {
    final String lower = fileName.toLowerCase();
    final String? ext = _extension(lower);
    final String? fromExt = ext != null ? _mimeFromExtension(ext) : null;
    final String? fromMagic = lookupMimeType(
      fileName,
      headerBytes: bytes.isEmpty ? null : bytes,
    );
    final String raw = fromMagic ?? fromExt ?? 'application/octet-stream';
    return _normalizeForServer(raw, ext);
  }

  static String? _extension(String lowerName) {
    final int dot = lowerName.lastIndexOf('.');
    if (dot < 0 || dot >= lowerName.length - 1) {
      return null;
    }
    return lowerName.substring(dot + 1);
  }

  /// Extension fallbacks when magic bytes are missing or ambiguous.
  static String? _mimeFromExtension(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/m4a';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
      case 'text':
        return 'text/plain';
      default:
        return null;
    }
  }

  static String _normalizeForServer(String mime, String? ext) {
    final String m = mime.toLowerCase();
    if (m == 'audio/mp4' && (ext == 'm4a' || ext == 'aac')) {
      return 'audio/m4a';
    }
    if (m == 'video/x-msvideo') {
      return 'video/mp4';
    }
    if (m.startsWith('image/')) {
      if (m == 'image/jpg') {
        return 'image/jpeg';
      }
      return m;
    }
    if (m.startsWith('video/')) {
      return m;
    }
    if (m.startsWith('audio/')) {
      if (m == 'audio/x-m4a' || m == 'audio/mp4') {
        return 'audio/m4a';
      }
      return m;
    }
    if (m.startsWith('application/') || m.startsWith('text/')) {
      return m;
    }
    if (m == 'application/octet-stream') {
      final String? e = ext;
      if (e != null) {
        final String? mapped = _mimeFromExtension(e);
        if (mapped != null) {
          return mapped;
        }
      }
      return 'application/octet-stream';
    }
    return m;
  }
}

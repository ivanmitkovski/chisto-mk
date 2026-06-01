/// Server caps — keep in sync with Nest
/// `apps/api/src/event-chat/event-chat-upload.service.ts`
/// (`MAX_*_SIZE`, `MAX_FILES_PER_MESSAGE`, mime sets). Enforced client-side before
/// upload to fail fast. Cleanup evidence uploads use the reports pipeline, not these caps.
abstract final class ChatUploadLimits {
  static const int maxFilesPerMessage = 5;
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxVideoBytes = 25 * 1024 * 1024;
  static const int maxAudioBytes = 10 * 1024 * 1024;
  static const int maxDocBytes = 10 * 1024 * 1024;

  static const Set<String> imageMimes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
  };
  static const Set<String> videoMimes = <String>{
    'video/mp4',
    'video/quicktime',
    'video/webm',
  };
  static const Set<String> audioMimes = <String>{
    'audio/mpeg',
    'audio/mp3',
    'audio/aac',
    'audio/m4a',
    'audio/ogg',
    'audio/wav',
  };
  static const Set<String> docMimes = <String>{
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
  };

  static int maxBytesForMime(String mimeLower) {
    if (videoMimes.contains(mimeLower)) {
      return maxVideoBytes;
    }
    if (audioMimes.contains(mimeLower)) {
      return maxAudioBytes;
    }
    if (docMimes.contains(mimeLower)) {
      return maxDocBytes;
    }
    return maxImageBytes;
  }

  static bool isAllowedMime(String mimeLower) {
    return imageMimes.contains(mimeLower) ||
        videoMimes.contains(mimeLower) ||
        audioMimes.contains(mimeLower) ||
        docMimes.contains(mimeLower);
  }
}

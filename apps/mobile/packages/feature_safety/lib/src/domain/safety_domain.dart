import 'package:chisto_infrastructure/core/serialization/safe_json.dart';

/// A user blocked by the authenticated citizen (`GET /users/me/blocks`).
class BlockedUserRow {
  const BlockedUserRow({
    required this.blockedUserId,
    required this.displayName,
    this.createdAt,
  });

  factory BlockedUserRow.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? blocked = safeAsStringKeyedMap(json['blocked']);
    final String blockedUserId =
        (json['blockedUserId'] as String? ?? blocked?['id'] as String? ?? '')
            .trim();
    final String first = blocked?['firstName'] as String? ?? '';
    final String last = blocked?['lastName'] as String? ?? '';
    final String name = '$first $last'.trim();
    final String? createdRaw = json['createdAt'] as String?;
    return BlockedUserRow(
      blockedUserId: blockedUserId,
      displayName: name.isNotEmpty ? name : blockedUserId,
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }

  final String blockedUserId;
  final String displayName;
  final DateTime? createdAt;
}

/// UGC report + block APIs (App Store Guideline 1.2).
abstract class UgcModerationRepositoryPort {
  Future<void> submitReport({
    required String subjectType,
    required String subjectId,
    required String reason,
    String? details,
  });

  Future<void> blockUser(String blockedUserId);

  Future<List<BlockedUserRow>> listBlocks();

  Future<void> unblockUser(String blockedUserId);
}

/// Blocks a user after validating the target is not the signed-in user.
class BlockUserUseCase {
  const BlockUserUseCase({required UgcModerationRepositoryPort repository})
    : _repository = repository;

  final UgcModerationRepositoryPort _repository;

  /// Returns [BlockUserOutcome.self] when [blockedUserId] matches [currentUserId].
  Future<BlockUserOutcome> call({
    required String blockedUserId,
    required String? currentUserId,
  }) async {
    final String id = blockedUserId.trim();
    if (id.isEmpty) {
      return BlockUserOutcome.invalidTarget;
    }
    if (currentUserId != null && currentUserId == id) {
      return BlockUserOutcome.self;
    }
    await _repository.blockUser(id);
    return BlockUserOutcome.success;
  }
}

enum BlockUserOutcome { success, self, invalidTarget }

/// Submits a moderation report for UGC content.
class SubmitUgcReportUseCase {
  const SubmitUgcReportUseCase({
    required UgcModerationRepositoryPort repository,
  }) : _repository = repository;

  final UgcModerationRepositoryPort _repository;

  Future<void> call({
    required String subjectType,
    required String subjectId,
    required String reason,
    String? details,
  }) {
    return _repository.submitReport(
      subjectType: subjectType,
      subjectId: subjectId,
      reason: reason,
      details: details,
    );
  }
}

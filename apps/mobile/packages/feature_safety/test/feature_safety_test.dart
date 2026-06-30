import 'package:feature_safety/feature_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BlockUserUseCase rejects self-block', () async {
    final _FakeRepo repo = _FakeRepo();
    final BlockUserUseCase useCase = BlockUserUseCase(repository: repo);
    final BlockUserOutcome outcome = await useCase.call(
      blockedUserId: 'user-1',
      currentUserId: 'user-1',
    );
    expect(outcome, BlockUserOutcome.self);
    expect(repo.blockedIds, isEmpty);
  });
}

class _FakeRepo implements UgcModerationRepositoryPort {
  final List<String> blockedIds = <String>[];

  @override
  Future<void> blockUser(String blockedUserId) async {
    blockedIds.add(blockedUserId);
  }

  @override
  Future<List<BlockedUserRow>> listBlocks() async => <BlockedUserRow>[];

  @override
  Future<void> submitReport({
    required String subjectType,
    required String subjectId,
    required String reason,
    String? details,
  }) async {}

  @override
  Future<void> unblockUser(String blockedUserId) async {}
}

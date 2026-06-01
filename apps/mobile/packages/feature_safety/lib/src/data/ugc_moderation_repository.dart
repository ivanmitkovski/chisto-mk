import 'dart:convert';

import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_safety/src/domain/safety_domain.dart' as safety;

/// App-layer implementation of [safety.UgcModerationRepositoryPort].
class UgcModerationRepository implements safety.UgcModerationRepositoryPort {
  UgcModerationRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<void> submitReport({
    required String subjectType,
    required String subjectId,
    required String reason,
    String? details,
  }) async {
    await _client.post(
      '/moderation/reports',
      body: <String, dynamic>{
        'subjectType': subjectType,
        'subjectId': subjectId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }

  @override
  Future<void> blockUser(String blockedUserId) async {
    await _client.post(
      '/users/me/blocks',
      body: <String, dynamic>{'blockedUserId': blockedUserId},
    );
  }

  @override
  Future<List<safety.BlockedUserRow>> listBlocks() async {
    final ApiResponse res = await _client.get('/users/me/blocks');
    final List<dynamic> rows = _decodeBlocksPayload(res);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(safety.BlockedUserRow.fromJson)
        .where((safety.BlockedUserRow row) => row.blockedUserId.isNotEmpty)
        .toList(growable: false);
  }

  static List<dynamic> _decodeBlocksPayload(ApiResponse res) {
    final String? body = res.body;
    if (body == null || body.trim().isEmpty) {
      return <dynamic>[];
    }
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded;
      }
    } on Object {
      // fall through
    }
    return <dynamic>[];
  }

  @override
  Future<void> unblockUser(String blockedUserId) async {
    await _client.delete('/users/me/blocks/$blockedUserId');
  }
}

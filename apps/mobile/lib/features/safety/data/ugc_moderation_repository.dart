import 'dart:convert';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/safety/domain/blocked_user_row.dart';

/// UGC report + block APIs (App Store Guideline 1.2).
class UgcModerationRepository {
  UgcModerationRepository({ApiClient? client})
      : _client = client ?? AppBootstrap.instance.apiClient;

  final ApiClient _client;

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
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      },
    );
  }

  Future<void> blockUser(String blockedUserId) async {
    await _client.post(
      '/users/me/blocks',
      body: <String, dynamic>{'blockedUserId': blockedUserId},
    );
  }

  Future<List<BlockedUserRow>> listBlocks() async {
    final ApiResponse res = await _client.get('/users/me/blocks');
    final List<dynamic> rows = _decodeBlocksPayload(res);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(BlockedUserRow.fromJson)
        .where((BlockedUserRow row) => row.blockedUserId.isNotEmpty)
        .toList(growable: false);
  }

  /// Nest returns a JSON array; [ApiClient] only maps object bodies into [ApiResponse.json].
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

  Future<void> unblockUser(String blockedUserId) async {
    await _client.delete('/users/me/blocks/$blockedUserId');
  }
}

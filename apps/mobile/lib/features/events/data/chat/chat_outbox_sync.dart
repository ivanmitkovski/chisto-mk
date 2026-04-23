import 'dart:math' show min;

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';

/// Outcome of attempting to send a single outboxed chat message.
enum ChatOutboxFlushKind {
  /// Message reached the server and the row was removed from SQLite.
  sent,

  /// Transient failure; row kept as pending with incremented attempts.
  deferredRetryable,

  /// Non-retryable [AppError]; row marked failed in SQLite.
  terminalFailed,

  /// Non-[AppError] failure; treated like retryable for coordinator resilience.
  deferredUnknown,
}

class ChatOutboxFlushResult {
  ChatOutboxFlushResult.sent(this.savedMessage) : kind = ChatOutboxFlushKind.sent;

  ChatOutboxFlushResult.deferredRetryable()
      : kind = ChatOutboxFlushKind.deferredRetryable,
        savedMessage = null;

  ChatOutboxFlushResult.terminalFailed()
      : kind = ChatOutboxFlushKind.terminalFailed,
        savedMessage = null;

  ChatOutboxFlushResult.deferredUnknown()
      : kind = ChatOutboxFlushKind.deferredUnknown,
        savedMessage = null;

  final ChatOutboxFlushKind kind;
  final EventChatMessage? savedMessage;
}

/// Sends one queued chat row with the same idempotency contract as online send.
class ChatOutboxSync {
  ChatOutboxSync._();

  /// Exponential backoff capped at 30s from post-failure [attemptCount]
  /// (after [ChatOutboxStore.recordRetryableFailure], pass previous + 1).
  static Duration retryDelayAfterAttempt(int attemptCount) {
    final int capped = min(attemptCount, 8);
    final int ms = min(30000, 200 * (1 << capped));
    return Duration(milliseconds: ms < 200 ? 200 : ms);
  }

  static Future<ChatOutboxFlushResult> flushOne({
    required EventChatRepository repo,
    required ChatOutboxStore store,
    required ChatOutboxEntry entry,
  }) async {
    try {
      final EventChatMessage saved = await repo.sendMessage(
        entry.eventId,
        entry.body,
        replyToId: entry.replyToId,
        clientMessageId: entry.clientMessageId,
      );
      await store.remove(entry.eventId, entry.clientMessageId);
      return ChatOutboxFlushResult.sent(saved);
    } on AppError catch (e) {
      if (e.retryable) {
        await store.recordRetryableFailure(
          entry.eventId,
          entry.clientMessageId,
          lastErrorCode: e.code,
        );
        logEventsDiagnostic('chat_outbox_flush_deferred');
        return ChatOutboxFlushResult.deferredRetryable();
      }
      await store.markTerminalFailure(entry.eventId, entry.clientMessageId, e.code);
      logEventsDiagnostic('chat_outbox_terminal');
      return ChatOutboxFlushResult.terminalFailed();
    } on Object catch (_) {
      await store.recordRetryableFailure(
        entry.eventId,
        entry.clientMessageId,
        lastErrorCode: 'UNKNOWN',
      );
      logEventsDiagnostic('chat_outbox_flush_deferred_unknown');
      return ChatOutboxFlushResult.deferredUnknown();
    }
  }
}

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_events/src/data/chat/api_event_chat_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/in_memory_event_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currentConnectionStatus is disconnected before realtime starts', () {
    final AuthState auth = AuthState();
    final ApiClient client = ApiClient(
      config: AppConfig.local,
      accessToken: () => null,
      onUnauthorized: () {},
    );
    final ApiEventChatRepository repo = ApiEventChatRepository(
      client: client,
      config: AppConfig.local,
      authState: auth,
    );
    expect(
      repo.currentConnectionStatus('event-1'),
      EventChatConnectionStatus.disconnected,
    );
  });

  test(
    'in-memory connectionStatus replays current status to new subscribers',
    () async {
      final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
      repo.setConnectionStatusForTest(
        'e1',
        EventChatConnectionStatus.connected,
      );

      expect(
        await repo.connectionStatus('e1').first,
        EventChatConnectionStatus.connected,
      );

      final List<EventChatConnectionStatus> events =
          <EventChatConnectionStatus>[];
      final sub = repo.connectionStatus('e1').listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(events.first, EventChatConnectionStatus.connected);
      await sub.cancel();
      repo.dispose();
    },
  );
}

import { EventChatClusterConfig } from '../../src/event-chat/event-chat-cluster.config';
import { EventChatGateway } from '../../src/event-chat/event-chat.gateway';
import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatTelemetryService } from '../../src/event-chat/event-chat-telemetry.service';

describe('EventChatSseService', () => {
  const originalRedis = process.env.REDIS_URL;

  afterEach(() => {
    if (originalRedis === undefined) {
      delete process.env.REDIS_URL;
    } else {
      process.env.REDIS_URL = originalRedis;
    }
  });

  it('ingestFromRedis does not emit to WebSocket gateway when Socket.IO is clustered', () => {
    delete process.env.REDIS_URL;
    const gateway = { server: {}, emitToRoom: jest.fn() } as unknown as EventChatGateway;
    const cluster = new EventChatClusterConfig();
    cluster.setSocketIoClustered(true);
    const telemetry = new EventChatTelemetryService();
    const svc = new EventChatSseService(gateway, cluster, telemetry);

    const payload = JSON.stringify({
      streamEventId: 'se-1',
      eventId: 'evt-1',
      type: 'message_created',
      message: { id: 'm1', body: 'hi' },
    });
    (svc as unknown as { ingestFromRedis: (eid: string, p: string) => void }).ingestFromRedis(
      'evt-1',
      payload,
    );

    expect(gateway.emitToRoom).not.toHaveBeenCalled();
  });

  it('ingestFromRedis emits to WebSocket gateway when Socket.IO is not clustered', () => {
    delete process.env.REDIS_URL;
    const gateway = { server: {}, emitToRoom: jest.fn() } as unknown as EventChatGateway;
    const cluster = new EventChatClusterConfig();
    cluster.setSocketIoClustered(false);
    const telemetry = new EventChatTelemetryService();
    const svc = new EventChatSseService(gateway, cluster, telemetry);

    const payload = JSON.stringify({
      streamEventId: 'se-2',
      eventId: 'evt-2',
      type: 'message_created',
      message: { id: 'm2', body: 'yo' },
    });
    (svc as unknown as { ingestFromRedis: (eid: string, p: string) => void }).ingestFromRedis(
      'evt-2',
      payload,
    );

    expect(gateway.emitToRoom).toHaveBeenCalledWith(
      'evt-2',
      'message_created',
      expect.objectContaining({ streamEventId: 'se-2', eventId: 'evt-2' }),
    );
  });
});

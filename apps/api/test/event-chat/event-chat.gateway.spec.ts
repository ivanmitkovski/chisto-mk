import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatGateway } from '../../src/event-chat/event-chat.gateway';

describe('EventChatGateway replay on join', () => {
  it('emits sync when replay buffer has events after lastStreamEventId', async () => {
    const getReplaySince = jest.fn().mockReturnValue([
      {
        streamEventId: 'se-2',
        eventId: 'evt-1',
        type: 'message_created',
        message: { id: 'm-2', eventId: 'evt-1', body: 'hi' },
      },
    ]);
    const realtime = { getReplaySince } as unknown as EventChatSseService;

    const emitted: Array<{ event: string; payload: unknown }> = [];
    const client = {
      id: 'sock-1',
      data: { userId: 'u1' },
      join: jest.fn().mockResolvedValue(undefined),
      emit: jest.fn((event: string, payload: unknown) => {
        emitted.push({ event, payload });
      }),
    };

    const gateway = new EventChatGateway(
      { get: jest.fn() } as never,
      {} as never,
      {
        assertCanAccessEventChat: jest.fn().mockResolvedValue(undefined),
      } as never,
      { attachServer: jest.fn() } as never,
      realtime,
    );

    await gateway.handleJoin(client as never, {
      eventId: 'evt-1',
      lastStreamEventId: 'se-1',
    });

    expect(getReplaySince).toHaveBeenCalledWith('evt-1', 'se-1');
    expect(emitted).toEqual([
      expect.objectContaining({
        event: 'sync',
        payload: expect.objectContaining({
          eventId: 'evt-1',
          events: expect.any(Array),
        }),
      }),
    ]);
  });
});

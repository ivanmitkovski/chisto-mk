import { EMPTY } from 'rxjs';
import { EventChatController } from '../../src/event-chat/event-chat.controller';
import { EventChatService } from '../../src/event-chat/event-chat.service';
import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatUploadService } from '../../src/event-chat/event-chat-upload.service';

describe('EventChatController', () => {
  it('constructs with service dependencies', () => {
    const sse: Pick<EventChatSseService, 'getReplaySince' | 'getStream'> = {
      getReplaySince: () => [],
      getStream: () => EMPTY,
    };
    const controller = new EventChatController(
      {} as EventChatService,
      sse as EventChatSseService,
      {} as EventChatUploadService,
    );
    expect(controller).toBeDefined();
  });
});

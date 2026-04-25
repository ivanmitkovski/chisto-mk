import { EMPTY } from 'rxjs';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventChatController } from '../../src/event-chat/event-chat.controller';
import { EventChatService } from '../../src/event-chat/event-chat.service';
import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatUploadService } from '../../src/event-chat/event-chat-upload.service';

describe('EventChatController', () => {
  const user: AuthenticatedUser = {
    userId: 'u-chat-1',
    email: 'u@chisto.mk',
    phoneNumber: '+38970000001',
    role: Role.USER,
  };

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

  it('unreadCount delegates to EventChatService', async () => {
    const unreadCount = jest.fn().mockResolvedValue({ count: 3 });
    const sse: Pick<EventChatSseService, 'getReplaySince' | 'getStream'> = {
      getReplaySince: () => [],
      getStream: () => EMPTY,
    };
    const controller = new EventChatController(
      { unreadCount } as unknown as EventChatService,
      sse as EventChatSseService,
      {} as EventChatUploadService,
    );

    await expect(controller.unreadCount(user, 'evt-1')).resolves.toEqual({ count: 3 });
    expect(unreadCount).toHaveBeenCalledWith('evt-1', user);
  });
});

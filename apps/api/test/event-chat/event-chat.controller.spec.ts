import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventChatReadController } from '../../src/event-chat/event-chat-read.controller';
import { EventChatListService } from '../../src/event-chat/event-chat-list.service';
import { EventChatPresenceService } from '../../src/event-chat/event-chat-presence.service';

describe('EventChatReadController', () => {
  const user: AuthenticatedUser = {
    userId: 'u-chat-1',
    email: 'u@chisto.mk',
    phoneNumber: '+38970000001',
    role: Role.USER,
  };

  it('constructs with service dependencies', () => {
    const controller = new EventChatReadController(
      {} as EventChatListService,
      {} as EventChatPresenceService,
    );
    expect(controller).toBeDefined();
  });

  it('unreadCount delegates to EventChatPresenceService', async () => {
    const unreadCount = jest.fn().mockResolvedValue({ count: 3 });
    const controller = new EventChatReadController(
      {} as EventChatListService,
      { unreadCount } as unknown as EventChatPresenceService,
    );

    await expect(controller.unreadCount(user, 'evt-1')).resolves.toEqual({ count: 3 });
    expect(unreadCount).toHaveBeenCalledWith('evt-1', user);
  });
});

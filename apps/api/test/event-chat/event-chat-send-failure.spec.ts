import { Prisma } from '../../src/prisma-client';
import { PrismaService } from '../../src/prisma/prisma.service';
import { NotificationDispatcherService } from '../../src/notifications/notification-dispatcher.service';
import { ChatEncryptionService } from '../../src/event-chat/chat-encryption.service';
import { EventChatListService } from '../../src/event-chat/event-chat-list.service';
import { EventChatMessageDtoService } from '../../src/event-chat/event-chat-message-dto.service';
import { EventChatMutationsService } from '../../src/event-chat/event-chat-mutations.service';
import { EventChatNotificationsService } from '../../src/event-chat/event-chat-notifications.service';
import { EventChatPresenceService } from '../../src/event-chat/event-chat-presence.service';
import { EventChatService } from '../../src/event-chat/event-chat.service';
import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatTelemetryService } from '../../src/event-chat/event-chat-telemetry.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

describe('EventChatService send failures', () => {
  const eventId = 'evt_fail';
  const user: AuthenticatedUser = {
    userId: 'u1',
    email: 'a@b.c',
    phoneNumber: '+100',
    role: 'USER' as const,
  };

  it('emits telemetry when prisma create fails unexpectedly', async () => {
    const prisma = {
      eventChatMessage: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(() => {
          throw new Prisma.PrismaClientKnownRequestError('dup', {
            code: 'P2003',
            clientVersion: 'test',
          });
        }),
      },
    };
    const sse = { emitEvent: jest.fn() };
    const telemetry = {
      emitMetric: jest.fn(),
      emitSpan: jest.fn(),
      emitAudit: jest.fn(),
    };
    const encryption = {
      enabled: false,
      encrypt: jest.fn((v: string) => v),
      decrypt: jest.fn((v: string) => v),
    };
    const chatUpload = {
      deleteUploadedObjectsByUrls: jest.fn().mockResolvedValue(undefined),
      applySignedUrlsToMessageDto: jest.fn(async (d: unknown) => d),
    };
    const uploads = { signPrivateObjectKey: jest.fn().mockResolvedValue(null) };

    const cn = new EventChatNotificationsService(
      prisma as unknown as PrismaService,
      {} as unknown as NotificationDispatcherService,
    );
    const dto = new EventChatMessageDtoService(
      encryption as unknown as ChatEncryptionService,
      chatUpload as never,
      uploads as never,
    );
    const list = new EventChatListService(
      prisma as unknown as PrismaService,
      telemetry as unknown as EventChatTelemetryService,
      dto,
    );
    const presence = new EventChatPresenceService(
      prisma as unknown as PrismaService,
      sse as unknown as EventChatSseService,
      uploads as never,
    );
    const mutations = new EventChatMutationsService(
      prisma as unknown as PrismaService,
      sse as unknown as EventChatSseService,
      cn,
      encryption as unknown as ChatEncryptionService,
      chatUpload as never,
      telemetry as unknown as EventChatTelemetryService,
      dto,
    );
    const service = new EventChatService(list, presence, mutations);

    await expect(service.sendMessage(eventId, user, { body: 'hi' } as never)).rejects.toBeInstanceOf(
      Prisma.PrismaClientKnownRequestError,
    );
    expect(telemetry.emitMetric).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'event_chat.message.send_failed', ok: false }),
    );
    expect(sse.emitEvent).not.toHaveBeenCalled();
  });
});

import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { EventChatMessageType, NotificationType } from '../../src/prisma-client';
import { PrismaService } from '../../src/prisma/prisma.service';
import { NotificationDispatcherService } from '../../src/notifications/notification-dispatcher.service';
import { ChatEncryptionService } from '../../src/event-chat/chat-encryption.service';
import { EventChatService } from '../../src/event-chat/event-chat.service';
import { EventChatSseService } from '../../src/event-chat/event-chat-sse.service';
import { EventChatTelemetryService } from '../../src/event-chat/event-chat-telemetry.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

const baseMsgRow = {
  editedAt: null,
  isPinned: false,
  pinnedAt: null,
  pinnedById: null,
  messageType: EventChatMessageType.TEXT,
  systemPayload: null,
  pinnedBy: null,
  bodyEncrypted: false,
  clientMessageId: null as string | null,
  attachments: [] as unknown[],
  locationLat: null as number | null,
  locationLng: null as number | null,
  locationLabel: null as string | null,
};

describe('EventChatService', () => {
  const eventId = 'evt_1';
  const user: AuthenticatedUser = {
    userId: 'u1',
    email: 'a@b.c',
    phoneNumber: '+100',
    role: 'USER' as const,
  };

  let service: EventChatService;
  let prisma: {
    cleanupEvent: { findUnique: jest.Mock; findFirst: jest.Mock };
    user: { findUnique: jest.Mock };
    eventParticipant: { findMany: jest.Mock; findUnique: jest.Mock };
    eventChatAttachment: { deleteMany: jest.Mock };
    $transaction: jest.Mock;
    eventChatMessage: {
      findMany: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      count: jest.Mock;
    };
    eventChatReadCursor: { findUnique: jest.Mock; findMany: jest.Mock; upsert: jest.Mock };
    eventChatMute: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      upsert: jest.Mock;
      deleteMany: jest.Mock;
    };
  };
  let sse: { emitEvent: jest.Mock };
  let dispatcher: { dispatchToUser: jest.Mock };
  let telemetry: { emitMetric: jest.Mock; emitSpan: jest.Mock; emitAudit: jest.Mock };

  beforeEach(async () => {
    prisma = {
      cleanupEvent: { findUnique: jest.fn(), findFirst: jest.fn() },
      user: { findUnique: jest.fn() },
      eventParticipant: { findMany: jest.fn(), findUnique: jest.fn() },
      eventChatAttachment: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      $transaction: jest.fn((arg: unknown) => {
        if (Array.isArray(arg)) {
          return Promise.all(arg as Promise<unknown>[]);
        }
        return Promise.reject(new Error('expected array transaction'));
      }),
      eventChatMessage: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        count: jest.fn(),
      },
      eventChatReadCursor: { findUnique: jest.fn(), findMany: jest.fn(), upsert: jest.fn() },
      eventChatMute: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
      },
    };
    sse = { emitEvent: jest.fn() };
    dispatcher = { dispatchToUser: jest.fn().mockResolvedValue(undefined) };
    telemetry = {
      emitMetric: jest.fn(),
      emitSpan: jest.fn(),
      emitAudit: jest.fn(),
    };

    const encryption = { enabled: false, encrypt: jest.fn((v: string) => v), decrypt: jest.fn((v: string) => v) };
    const chatUpload = {
      deleteUploadedObjectsByUrls: jest.fn().mockResolvedValue(undefined),
      applySignedUrlsToMessageDto: jest.fn(async (d: unknown) => d),
    };
    const uploads = {
      signPrivateObjectKey: jest.fn().mockResolvedValue(null),
    };
    service = new EventChatService(
      prisma as unknown as PrismaService,
      sse as unknown as EventChatSseService,
      dispatcher as unknown as NotificationDispatcherService,
      encryption as unknown as ChatEncryptionService,
      chatUpload as never,
      uploads as never,
      telemetry as unknown as EventChatTelemetryService,
    );
  });

  it('listMessages returns newest-first page', async () => {
    prisma.eventChatMessage.findMany.mockResolvedValue([
      {
        ...baseMsgRow,
        id: 'm2',
        eventId,
        createdAt: new Date('2026-01-02T00:00:00Z'),
        body: 'b2',
        deletedAt: null,
        replyToId: null,
        authorId: 'u2',
        author: { id: 'u2', firstName: 'A', lastName: 'B', avatarObjectKey: null },
        replyTo: null,
      },
    ]);

    const res = await service.listMessages(eventId, user, { limit: 50 } as never);
    expect(res.data).toHaveLength(1);
    expect(res.data[0]!.id).toBe('m2');
    expect(res.meta.hasMore).toBe(false);
    expect(prisma.eventChatMessage.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      }),
    );
  });

  it('listMessages throws on invalid cursor', async () => {
    prisma.eventChatMessage.findFirst.mockResolvedValueOnce(null);
    await expect(
      service.listMessages(eventId, user, { limit: 10, cursor: 'bad' } as never),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('sendMessage creates row and emits SSE', async () => {
    const created = {
      ...baseMsgRow,
      id: 'm_new',
      eventId,
      createdAt: new Date(),
      body: 'hello',
      deletedAt: null,
      replyToId: null,
      authorId: user.userId,
      author: { id: user.userId, firstName: 'Me', lastName: 'User', avatarObjectKey: null },
      replyTo: null,
    };
    prisma.eventChatMessage.create.mockResolvedValue(created);
    prisma.cleanupEvent.findUnique.mockResolvedValue({
      title: 'River',
      organizerId: 'org1',
    });
    prisma.eventParticipant.findMany.mockResolvedValue([{ userId: 'u2' }]);
    prisma.eventChatMute.findMany.mockResolvedValue([]);

    const res = await service.sendMessage(eventId, user, { body: '  hello  ' } as never);
    expect(res.data.body).toBe('hello');
    expect(res.data.clientMessageId).toBeNull();
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventId,
        type: 'message_created',
        message: expect.objectContaining({ id: 'm_new' }),
      }),
    );
    expect(telemetry.emitMetric).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'event_chat.message.sent', ok: true }),
    );

    await new Promise((r) => setTimeout(r, 0));
    expect(dispatcher.dispatchToUser).toHaveBeenCalledWith(
      'u2',
      expect.objectContaining({
        type: NotificationType.EVENT_CHAT,
        threadKey: `event-chat:${eventId}`,
        data: expect.objectContaining({
          threadTitle: 'River',
        }),
      }),
    );
  });

  it('sendMessage returns existing row for same clientMessageId (idempotent)', async () => {
    const clientMessageId = '550e8400-e29b-41d4-a716-446655440000';
    const existing = {
      ...baseMsgRow,
      id: 'm_existing',
      eventId,
      createdAt: new Date('2026-01-01T00:00:00Z'),
      body: 'original',
      deletedAt: null,
      replyToId: null,
      authorId: user.userId,
      author: { id: user.userId, firstName: 'Me', lastName: 'User', avatarObjectKey: null },
      replyTo: null,
      clientMessageId,
    };
    prisma.eventChatMessage.findFirst.mockResolvedValue(existing);

    const res = await service.sendMessage(eventId, user, {
      body: 'duplicate attempt',
      clientMessageId,
    } as never);

    expect(res.data.id).toBe('m_existing');
    expect(res.data.body).toBe('original');
    expect(prisma.eventChatMessage.create).not.toHaveBeenCalled();
    expect(sse.emitEvent).not.toHaveBeenCalled();
  });

  it('sendMessage allows empty body when attachments are present (voice)', async () => {
    const created = {
      ...baseMsgRow,
      id: 'm_voice',
      eventId,
      createdAt: new Date(),
      body: '',
      deletedAt: null,
      replyToId: null,
      authorId: user.userId,
      author: { id: user.userId, firstName: 'Me', lastName: 'User', avatarObjectKey: null },
      replyTo: null,
      messageType: EventChatMessageType.AUDIO,
      attachments: [
        {
          id: 'att1',
          url: 'https://example.com/voice.m4a',
          mimeType: 'audio/m4a',
          fileName: 'voice.m4a',
          sizeBytes: 2048,
          width: null,
          height: null,
          duration: null,
          thumbnailUrl: null,
        },
      ],
    };
    prisma.eventChatMessage.create.mockResolvedValue(created);
    prisma.cleanupEvent.findUnique.mockResolvedValue({
      title: 'River',
      organizerId: 'org1',
    });
    prisma.eventParticipant.findMany.mockResolvedValue([]);
    prisma.eventChatMute.findMany.mockResolvedValue([]);

    const res = await service.sendMessage(eventId, user, {
      body: '',
      attachments: [
        {
          url: 'https://example.com/voice.m4a',
          mimeType: 'audio/m4a',
          fileName: 'voice.m4a',
          sizeBytes: 2048,
        },
      ],
    } as never);

    expect(res.data.messageType).toBe('AUDIO');
    expect(prisma.eventChatMessage.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          body: '',
          messageType: EventChatMessageType.AUDIO,
        }),
      }),
    );
  });

  it('notify skips muted recipients', async () => {
    const created = {
      ...baseMsgRow,
      id: 'm_new',
      eventId,
      createdAt: new Date(),
      body: 'hello',
      deletedAt: null,
      replyToId: null,
      authorId: user.userId,
      author: { id: user.userId, firstName: 'Me', lastName: 'User', avatarObjectKey: null },
      replyTo: null,
    };
    prisma.eventChatMessage.create.mockResolvedValue(created);
    prisma.cleanupEvent.findUnique.mockResolvedValue({
      title: 'River',
      organizerId: user.userId,
    });
    prisma.eventParticipant.findMany.mockResolvedValue([{ userId: 'u2' }]);
    prisma.eventChatMute.findMany.mockResolvedValue([{ userId: 'u2' }]);

    await service.sendMessage(eventId, user, { body: 'hello' } as never);
    await new Promise((r) => setTimeout(r, 0));
    expect(dispatcher.dispatchToUser).not.toHaveBeenCalled();
  });

  it('editMessage updates body and emits message_edited', async () => {
    prisma.eventChatMessage.findFirst.mockResolvedValue({
      ...baseMsgRow,
      id: 'm1',
      eventId,
      createdAt: new Date('2026-01-01T00:00:00Z'),
      body: 'old',
      deletedAt: null,
      authorId: user.userId,
      messageType: EventChatMessageType.TEXT,
      author: { id: user.userId, firstName: 'Me', lastName: 'U', avatarObjectKey: null },
      replyTo: null,
    });
    const updated = {
      ...baseMsgRow,
      id: 'm1',
      eventId,
      createdAt: new Date('2026-01-01T00:00:00Z'),
      body: 'new',
      deletedAt: null,
      replyToId: null,
      authorId: user.userId,
      editedAt: new Date(),
      author: { id: user.userId, firstName: 'Me', lastName: 'U', avatarObjectKey: null },
      replyTo: null,
      messageType: EventChatMessageType.TEXT,
    };
    prisma.eventChatMessage.update.mockResolvedValue(updated);

    const res = await service.editMessage(eventId, 'm1', user, { body: 'new' } as never);
    expect(res.data.body).toBe('new');
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'message_edited' }),
    );
    expect(telemetry.emitAudit).toHaveBeenCalledWith(
      'message_edited',
      expect.objectContaining({ actorId: user.userId, messageId: 'm1', eventId }),
    );
  });

  it('setMessagePin allows organizer and emits', async () => {
    prisma.eventChatMessage.findFirst.mockResolvedValue({
      id: 'm1',
      eventId,
      deletedAt: null,
      messageType: EventChatMessageType.TEXT,
      isPinned: false,
      event: { organizerId: user.userId },
    });
    prisma.eventChatMessage.count.mockResolvedValue(0);
    const updated = {
      ...baseMsgRow,
      id: 'm1',
      eventId,
      createdAt: new Date(),
      body: 'x',
      deletedAt: null,
      replyToId: null,
      authorId: 'u9',
      isPinned: true,
      pinnedAt: new Date(),
      pinnedById: user.userId,
      messageType: EventChatMessageType.TEXT,
      author: { id: 'u9', firstName: 'X', lastName: 'Y', avatarObjectKey: null },
      pinnedBy: { id: user.userId, firstName: 'Me', lastName: 'Org' },
      replyTo: null,
    };
    prisma.eventChatMessage.update.mockResolvedValue(updated);

    await service.setMessagePin(eventId, 'm1', user, { pinned: true } as never);
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'message_pinned' }),
    );
    expect(telemetry.emitAudit).toHaveBeenCalledWith(
      'message_pinned',
      expect.objectContaining({ actorId: user.userId, messageId: 'm1', eventId }),
    );
  });

  it('createSystemMessage emits message_created', async () => {
    const row = {
      ...baseMsgRow,
      id: 'sys1',
      eventId,
      createdAt: new Date(),
      body: 'Someone joined',
      deletedAt: null,
      replyToId: null,
      authorId: 'u2',
      messageType: EventChatMessageType.SYSTEM,
      systemPayload: { action: 'user_joined' },
      author: { id: 'u2', firstName: 'A', lastName: 'B', avatarObjectKey: null },
      replyTo: null,
    };
    prisma.eventChatMessage.create.mockResolvedValue(row);
    await service.createSystemMessage({
      eventId,
      authorId: 'u2',
      body: 'Someone joined',
      systemPayload: { action: 'user_joined' },
    });
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'message_created',
        message: expect.objectContaining({ messageType: 'SYSTEM' }),
      }),
    );
  });

  it('searchMessages filters by body', async () => {
    prisma.eventChatMessage.findMany.mockResolvedValue([
      {
        ...baseMsgRow,
        id: 'm1',
        eventId,
        createdAt: new Date(),
        body: 'hello river',
        deletedAt: null,
        replyToId: null,
        authorId: 'u2',
        author: { id: 'u2', firstName: 'A', lastName: 'B', avatarObjectKey: null },
        replyTo: null,
      },
    ]);
    const res = await service.searchMessages(eventId, user, {
      q: 'river',
      limit: 20,
    } as never);
    expect(res.data).toHaveLength(1);
    expect(prisma.eventChatMessage.findMany).toHaveBeenCalled();
  });

  it('setMuteStatus upserts when muted', async () => {
    prisma.eventChatMute.upsert.mockResolvedValue({});
    await service.setMuteStatus(eventId, user, { muted: true } as never);
    expect(prisma.eventChatMute.upsert).toHaveBeenCalled();
  });

  it('getMuteStatus reflects row', async () => {
    prisma.eventChatMute.findUnique.mockResolvedValue({ id: 'x' });
    const res = await service.getMuteStatus(eventId, user);
    expect(res.data.muted).toBe(true);
  });

  it('listParticipants returns count', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({ organizerId: 'org1' });
    prisma.user.findUnique.mockResolvedValue({
      id: 'org1',
      firstName: 'O',
      lastName: 'G',
      avatarObjectKey: null,
    });
    prisma.eventParticipant.findMany.mockImplementation((args: never) => {
      const a = args as { select?: Record<string, unknown> };
      if (a.select != null && 'userId' in a.select) {
        return Promise.resolve([{ userId: 'p1' }]);
      }
      return Promise.resolve([
        { user: { id: 'p1', firstName: 'P', lastName: 'One', avatarObjectKey: null } },
      ]);
    });

    const res = await service.listParticipants(eventId);
    expect(res.data.count).toBe(2);
    expect(res.data.participants.map((p) => p.id)).toContain('org1');
    expect(res.data.participants.map((p) => p.id)).toContain('p1');
  });

  it('softDeleteMessage forbids non-author (including when user is organizer)', async () => {
    prisma.eventChatMessage.findFirst.mockResolvedValue({
      id: 'm1',
      eventId,
      authorId: 'other',
      deletedAt: null,
      attachments: [],
    });
    await expect(service.softDeleteMessage(eventId, 'm1', user)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('softDeleteMessage allows author', async () => {
    prisma.eventChatMessage.findFirst.mockResolvedValue({
      id: 'm1',
      eventId,
      authorId: user.userId,
      deletedAt: null,
      attachments: [],
    });
    prisma.eventChatMessage.update.mockResolvedValue({});

    const res = await service.softDeleteMessage(eventId, 'm1', user);
    expect(res.data.ok).toBe(true);
    expect(prisma.eventChatAttachment.deleteMany).toHaveBeenCalledWith({
      where: { messageId: 'm1' },
    });
    expect(prisma.$transaction).toHaveBeenCalled();
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'message_deleted', messageId: 'm1' }),
    );
    expect(telemetry.emitAudit).toHaveBeenCalledWith(
      'message_deleted',
      expect.objectContaining({ actorId: user.userId, messageId: 'm1', eventId }),
    );
  });

  it('unreadCount uses cursor ref', async () => {
    prisma.eventChatReadCursor.findUnique.mockResolvedValue({ lastReadMessageId: 'm0' });
    prisma.eventChatMessage.findFirst.mockResolvedValue({
      id: 'm0',
      createdAt: new Date('2026-01-01T00:00:00Z'),
    });
    prisma.eventChatMessage.count.mockResolvedValue(3);

    const res = await service.unreadCount(eventId, user);
    expect(res.data.count).toBe(3);
    expect(prisma.eventChatMessage.count).toHaveBeenCalled();
  });

  it('patchReadCursor upserts', async () => {
    prisma.eventChatMessage.findFirst
      .mockResolvedValueOnce({ id: 'm1' })
      .mockResolvedValueOnce({ createdAt: new Date('2026-01-01T00:00:00.000Z') });
    prisma.eventChatReadCursor.upsert.mockResolvedValue({});
    prisma.user.findUnique.mockResolvedValue({ firstName: 'Pat', lastName: 'Lee' });

    await service.patchReadCursor(eventId, user, { lastReadMessageId: 'm1' } as never);
    expect(prisma.eventChatReadCursor.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId_userId: { eventId, userId: user.userId } },
        update: { lastReadMessageId: 'm1' },
      }),
    );
    expect(sse.emitEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventId,
        type: 'read_cursor_updated',
        persistInReplay: false,
        userId: user.userId,
        displayName: 'Pat Lee',
        lastReadMessageId: 'm1',
        lastReadMessageCreatedAt: new Date('2026-01-01T00:00:00.000Z').toISOString(),
      }),
    );
  });

  it('listReadCursors returns organizer and participants with cursor fields', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({ organizerId: 'org1' });
    prisma.user.findUnique.mockResolvedValue({
      id: 'org1',
      firstName: 'Org',
      lastName: 'User',
    });
    prisma.eventParticipant.findMany.mockResolvedValue([
      {
        user: { id: 'p1', firstName: 'Par', lastName: 'Ticipant' },
      },
    ]);
    prisma.eventChatReadCursor.findMany.mockResolvedValue([
      { userId: 'p1', lastReadMessageId: 'mid' },
    ]);
    prisma.eventChatMessage.findMany.mockResolvedValue([
      { id: 'mid', createdAt: new Date('2026-02-01T00:00:00.000Z') },
    ]);

    const res = await service.listReadCursors(eventId);
    expect(res.data.cursors).toHaveLength(2);
    expect(res.data.cursors[0]).toMatchObject({
      userId: 'org1',
      displayName: 'Org User',
      lastReadMessageId: null,
    });
    expect(res.data.cursors[1]).toMatchObject({
      userId: 'p1',
      displayName: 'Par Ticipant',
      lastReadMessageId: 'mid',
      lastReadMessageCreatedAt: '2026-02-01T00:00:00.000Z',
    });
  });

  it('recordTyping throttles rapid typing=true but emits typing=false', async () => {
    prisma.user.findUnique.mockResolvedValue({ firstName: 'A', lastName: 'B' });
    await service.recordTyping(eventId, user, true);
    await service.recordTyping(eventId, user, true);
    expect(sse.emitEvent).toHaveBeenCalledTimes(1);
    await service.recordTyping(eventId, user, false);
    expect(sse.emitEvent).toHaveBeenCalledTimes(2);
    expect(sse.emitEvent).toHaveBeenLastCalledWith(
      expect.objectContaining({
        eventId,
        type: 'typing_update',
        persistInReplay: false,
        typing: false,
      }),
    );
  });

  it('listMessages decrypts replyTo snippet when parent body is encrypted', async () => {
    const encryption = {
      enabled: true,
      encrypt: jest.fn((v: string) => v),
      decrypt: jest.fn((cipher: string) =>
        cipher === 'cipher-parent' ? 'Hello parent' : cipher,
      ),
    };
    const chatUpload = {
      deleteUploadedObjectsByUrls: jest.fn().mockResolvedValue(undefined),
      applySignedUrlsToMessageDto: jest.fn(async (d: unknown) => d),
    };
    const uploads = {
      signPrivateObjectKey: jest.fn().mockResolvedValue(null),
    };
    const svc = new EventChatService(
      prisma as unknown as PrismaService,
      sse as unknown as EventChatSseService,
      dispatcher as unknown as NotificationDispatcherService,
      encryption as unknown as ChatEncryptionService,
      chatUpload as never,
      uploads as never,
      telemetry as unknown as EventChatTelemetryService,
    );

    prisma.eventChatMessage.findMany.mockResolvedValue([
      {
        ...baseMsgRow,
        id: 'm_reply',
        eventId,
        createdAt: new Date('2026-01-03T00:00:00Z'),
        body: 'my reply',
        bodyEncrypted: false,
        deletedAt: null,
        replyToId: 'm_parent',
        authorId: user.userId,
        author: { id: user.userId, firstName: 'Me', lastName: 'User', avatarObjectKey: null },
        replyTo: {
          id: 'm_parent',
          body: 'cipher-parent',
          deletedAt: null,
          bodyEncrypted: true,
        },
        attachments: [],
      },
    ]);

    const res = await svc.listMessages(eventId, user, { limit: 50 } as never);
    expect(encryption.decrypt).toHaveBeenCalledWith('cipher-parent');
    expect(res.data[0]!.replyTo?.snippet).toBe('Hello parent');
  });
});

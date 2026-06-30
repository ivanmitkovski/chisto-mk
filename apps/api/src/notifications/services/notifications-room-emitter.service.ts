import { Injectable, Logger } from '@nestjs/common';
import type { Server } from 'socket.io';

export type NotificationSocketPayload = {
  notification?: Record<string, unknown>;
  unreadCount: number;
  id?: string;
};

@Injectable()
export class NotificationsRoomEmitterService {
  private readonly logger = new Logger(NotificationsRoomEmitterService.name);
  private server: Server | null = null;

  attachServer(server: Server): void {
    this.server = server;
  }

  isReady(): boolean {
    return this.server != null;
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }

  emitToUser(userId: string, event: string, payload: NotificationSocketPayload): void {
    if (!this.server) {
      this.logger.debug(`emit ${event} skipped: Socket.IO server not attached`);
      return;
    }
    this.server.to(this.userRoom(userId)).emit(event, payload);
  }

  emitNotificationNew(userId: string, payload: NotificationSocketPayload): void {
    this.emitToUser(userId, 'notification.new', payload);
  }

  emitNotificationUpdated(userId: string, payload: NotificationSocketPayload): void {
    this.emitToUser(userId, 'notification.updated', payload);
  }

  emitNotificationRead(userId: string, payload: NotificationSocketPayload): void {
    this.emitToUser(userId, 'notification.read', payload);
  }

  emitNotificationReadAll(userId: string, payload: NotificationSocketPayload): void {
    this.emitToUser(userId, 'notification.read_all', payload);
  }

  emitNotificationArchived(userId: string, payload: NotificationSocketPayload): void {
    this.emitToUser(userId, 'notification.archived', payload);
  }

  emitBadgeSync(userId: string, unreadCount: number): void {
    this.emitToUser(userId, 'badge.sync', { unreadCount });
  }
}

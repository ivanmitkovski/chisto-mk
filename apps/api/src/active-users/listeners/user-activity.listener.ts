import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { UserActivityService } from '../services/user-activity.service';
import { ActiveUsersSessionEnrichmentService } from '../services/active-users-session-enrichment.service';

type UserLoginPayload = {
  userId: string;
  sessionId: string;
  deviceId?: string | null;
  ipAddress?: string | null;
  deviceInfo?: string | null;
};

type ActivityPayload = {
  userId: string;
  metadata?: Record<string, unknown>;
  screen?: string | null;
};

@Injectable()
export class UserActivityListener {
  constructor(
    private readonly activity: UserActivityService,
    private readonly sessionEnrichment: ActiveUsersSessionEnrichmentService,
  ) {}

  @OnEvent('user.login', { async: true })
  async handleLogin(payload: UserLoginPayload): Promise<void> {
    await this.sessionEnrichment.onLogin(payload);
    await this.activity.recordSystemEvent({
      userId: payload.userId,
      type: 'LOGIN',
    });
  }

  @OnEvent('report.submitted', { async: true })
  async handleReportSubmitted(payload: ActivityPayload): Promise<void> {
    await this.activity.recordSystemEvent({
      userId: payload.userId,
      type: 'REPORT_SUBMITTED',
      ...(payload.metadata ? { metadata: payload.metadata } : {}),
    });
  }

  @OnEvent('report.created', { async: true })
  async handleReportCreated(payload: ActivityPayload): Promise<void> {
    await this.activity.recordSystemEvent({
      userId: payload.userId,
      type: 'REPORT_CREATED',
      ...(payload.metadata ? { metadata: payload.metadata } : {}),
    });
  }

  @OnEvent('event.joined', { async: true })
  async handleEventJoined(payload: ActivityPayload): Promise<void> {
    await this.activity.recordSystemEvent({
      userId: payload.userId,
      type: 'EVENT_JOINED',
      ...(payload.metadata ? { metadata: payload.metadata } : {}),
    });
  }

  @OnEvent('event.check_in', { async: true })
  async handleCheckIn(payload: ActivityPayload): Promise<void> {
    await this.activity.recordSystemEvent({
      userId: payload.userId,
      type: 'CHECK_IN',
      ...(payload.metadata ? { metadata: payload.metadata } : {}),
    });
  }
}

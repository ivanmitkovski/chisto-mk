import { HttpException, HttpStatus } from '@nestjs/common';

export const OTP_SEND_COOLDOWN_MS = 30_000;
export const OTP_SEND_MAX_PER_HOUR = 5;
export const OTP_SEND_WINDOW_MS = 60 * 60 * 1000;

type OtpSendState = {
  lastSentAt: Date | null;
  sendCountInWindow: number;
  sendWindowStartedAt: Date | null;
};

export function assertOtpSendAllowed(existing: OtpSendState | null, nowMs = Date.now()): {
  sendCountInWindow: number;
  sendWindowStartedAt: Date;
} {
  if (existing?.lastSentAt) {
    const sinceLast = nowMs - existing.lastSentAt.getTime();
    if (sinceLast < OTP_SEND_COOLDOWN_MS) {
      throw new HttpException(
        {
          code: 'OTP_SEND_COOLDOWN',
          message: 'Please wait before requesting another code',
          retryAfterSec: Math.ceil((OTP_SEND_COOLDOWN_MS - sinceLast) / 1000),
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  let sendCount = existing?.sendCountInWindow ?? 0;
  let windowStartMs = existing?.sendWindowStartedAt?.getTime() ?? nowMs;
  if (nowMs - windowStartMs >= OTP_SEND_WINDOW_MS) {
    sendCount = 0;
    windowStartMs = nowMs;
  }
  if (sendCount >= OTP_SEND_MAX_PER_HOUR) {
    throw new HttpException(
      {
        code: 'OTP_SEND_RATE_LIMIT',
        message: 'Too many codes requested for this phone number',
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  return {
    sendCountInWindow: sendCount + 1,
    sendWindowStartedAt: new Date(windowStartMs),
  };
}

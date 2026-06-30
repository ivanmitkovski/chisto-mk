import { BadRequestException } from '@nestjs/common';

export function encodeCursor(scheduledAt: Date, id: string): string {
  return Buffer.from(
    JSON.stringify({ s: scheduledAt.toISOString(), i: id }),
    'utf8',
  ).toString('base64url');
}

export function decodeCursor(cursor: string): { scheduledAt: Date; id: string } {
  let parsed: unknown;
  try {
    const raw = Buffer.from(cursor, 'base64url').toString('utf8');
    parsed = JSON.parse(raw) as unknown;
  } catch {
    throw new BadRequestException({
      code: 'INVALID_EVENTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    !('s' in parsed) ||
    !('i' in parsed)
  ) {
    throw new BadRequestException({
      code: 'INVALID_EVENTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const rec = parsed as { s: unknown; i: unknown };
  if (typeof rec.s !== 'string' || typeof rec.i !== 'string') {
    throw new BadRequestException({
      code: 'INVALID_EVENTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const scheduledAt = new Date(rec.s);
  if (Number.isNaN(scheduledAt.getTime())) {
    throw new BadRequestException({
      code: 'INVALID_EVENTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  return { scheduledAt, id: rec.i };
}

export function encodeParticipantCursor(joinedAt: Date, participantId: string): string {
  return Buffer.from(
    JSON.stringify({ j: joinedAt.toISOString(), i: participantId }),
    'utf8',
  ).toString('base64url');
}

export function decodeParticipantCursor(cursor: string): {
  joinedAt: Date;
  participantId: string;
} {
  let parsed: unknown;
  try {
    const raw = Buffer.from(cursor, 'base64url').toString('utf8');
    parsed = JSON.parse(raw) as unknown;
  } catch {
    throw new BadRequestException({
      code: 'INVALID_PARTICIPANTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    !('j' in parsed) ||
    !('i' in parsed)
  ) {
    throw new BadRequestException({
      code: 'INVALID_PARTICIPANTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const rec = parsed as { j: unknown; i: unknown };
  if (typeof rec.j !== 'string' || typeof rec.i !== 'string') {
    throw new BadRequestException({
      code: 'INVALID_PARTICIPANTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const joinedAt = new Date(rec.j);
  if (Number.isNaN(joinedAt.getTime())) {
    throw new BadRequestException({
      code: 'INVALID_PARTICIPANTS_CURSOR',
      message: 'Invalid cursor',
    });
  }
  return { joinedAt, participantId: rec.i };
}

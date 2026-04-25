export type CheckInAttendeesCursorPayload = { at: string; id: string };

export function encodeCheckInAttendeesCursor(checkedInAt: Date, id: string): string {
  const payload: CheckInAttendeesCursorPayload = {
    at: checkedInAt.toISOString(),
    id,
  };
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeCheckInAttendeesCursor(raw: string): { checkedInAt: Date; id: string } | null {
  try {
    const decoded = Buffer.from(raw, 'base64url').toString('utf8');
    const payload = JSON.parse(decoded) as CheckInAttendeesCursorPayload;
    const checkedInAt = new Date(payload.at);
    if (!Number.isFinite(checkedInAt.getTime()) || typeof payload.id !== 'string' || payload.id.length < 8) {
      return null;
    }
    return { checkedInAt, id: payload.id };
  } catch {
    return null;
  }
}

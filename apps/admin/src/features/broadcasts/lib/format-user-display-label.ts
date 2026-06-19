export type BroadcastUserLookupRow = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  status: string;
};

export function formatBroadcastUserLabel(user: Pick<BroadcastUserLookupRow, 'id' | 'firstName' | 'lastName' | 'email' | 'phoneNumber'>): string {
  const { primary, secondary } = getBroadcastUserDisplayParts(user);
  if (secondary) {
    return `${primary} · ${secondary}`;
  }
  return primary;
}

export function getBroadcastUserDisplayParts(
  user: Pick<BroadcastUserLookupRow, 'id' | 'firstName' | 'lastName' | 'email' | 'phoneNumber'>,
): { primary: string; secondary?: string } {
  const name = `${user.firstName} ${user.lastName}`.trim();
  if (name) {
    const secondary = user.email || user.phoneNumber || undefined;
    return { primary: name, secondary };
  }
  const fallback = user.email || user.phoneNumber || user.id;
  return { primary: fallback };
}

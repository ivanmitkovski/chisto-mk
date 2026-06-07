export function getInitials(firstName: string, lastName: string): string {
  const f = firstName?.trim().charAt(0) ?? '';
  const l = lastName?.trim().charAt(0) ?? '';
  return `${f}${l}`.toUpperCase() || '?';
}

export function formatRole(role: string): string {
  return role.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

export function getFeatureFlagDescription(metadata: unknown): string | null {
  if (metadata == null || typeof metadata !== 'object' || !('description' in metadata)) {
    return null;
  }
  const desc = (metadata as { description?: unknown }).description;
  return typeof desc === 'string' ? desc : null;
}

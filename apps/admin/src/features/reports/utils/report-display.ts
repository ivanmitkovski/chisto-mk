export function formatDateTime(value: string): string {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

/** Parses slaLabel (e.g. "2h remaining", "1h remaining") for urgency-based styling */
export function parseSlaUrgency(slaLabel: string): 'critical' | 'urgent' | 'normal' {
  const lower = slaLabel.toLowerCase();
  if (lower.includes('completed') || lower.includes('overdue') || lower.includes('n/a')) {
    return 'normal';
  }
  const match = lower.match(/(\d+)\s*(?:h|hr|hour)/);
  if (!match) return 'normal';
  const hours = parseInt(match[1], 10);
  if (hours <= 1) return 'critical';
  if (hours <= 2) return 'urgent';
  return 'normal';
}

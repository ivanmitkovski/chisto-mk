/** Turn browser rejection reasons (incl. script/link load Events) into readable text. */
export function describeClientRejection(reason: unknown): string {
  if (reason instanceof Error) return reason.message;
  if (reason instanceof Event) {
    const target = reason.target;
    if (target instanceof HTMLLinkElement) {
      return `Failed to load stylesheet: ${target.href || '(unknown)'}`;
    }
    if (target instanceof HTMLScriptElement) {
      return `Failed to load script: ${target.src || '(unknown)'}`;
    }
    return `Browser ${reason.type} event`;
  }
  if (typeof reason === 'string') return reason;
  return String(reason);
}

export function isDomLoadEventRejection(reason: unknown): reason is Event {
  return reason instanceof Event;
}

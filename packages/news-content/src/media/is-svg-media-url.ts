/** True when a media URL points at an SVG asset (ignores query string for presigned URLs). */
export function isSvgMediaUrl(src: string): boolean {
  if (!src) return false;

  try {
    const pathname = src.startsWith('http://') || src.startsWith('https://')
      ? new URL(src).pathname
      : src.split('?')[0] ?? src;
    return pathname.toLowerCase().endsWith('.svg');
  } catch {
    return src.split('?')[0]?.toLowerCase().endsWith('.svg') ?? false;
  }
}

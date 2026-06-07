export function formatEventDateTime(iso: string, locale?: string): string {
  const d = new Date(iso);
  return d.toLocaleString(locale, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

export function mapSiteLinks(lat: number, lng: number) {
  return {
    gm: `https://www.google.com/maps?q=${lat},${lng}`,
    am: `https://maps.apple.com/?q=${lat},${lng}`,
  };
}

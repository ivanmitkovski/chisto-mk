export function buildGoogleMapsUrl(latitude: number, longitude: number): string {
  return `https://www.google.com/maps?q=${latitude},${longitude}`;
}

export function buildAppleMapsUrl(latitude: number, longitude: number): string {
  return `https://maps.apple.com/?q=${latitude},${longitude}`;
}

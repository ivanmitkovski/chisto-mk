const HEIC_BRANDS = new Set(['heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1']);

/**
 * Detects HEIC/HEIF from ISO-BMFF magic (ftyp box) when declared MIME is ambiguous.
 */
export function detectHeicFromBuffer(buf: Buffer): boolean {
  if (buf.length < 12) {
    return false;
  }
  const ftyp = buf.subarray(4, 8).toString('ascii');
  if (ftyp !== 'ftyp') {
    return false;
  }
  const brand = buf.subarray(8, 12).toString('ascii');
  return HEIC_BRANDS.has(brand);
}

export function isHeicMime(mime: string): boolean {
  const normalized = mime.toLowerCase();
  return normalized === 'image/heic' || normalized === 'image/heif';
}

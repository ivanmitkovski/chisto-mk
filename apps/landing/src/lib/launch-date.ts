/** Launch moment: 1 May, start of day (Europe/Skopje). */
export const LAUNCH_ISO = "2026-05-01T00:00:00+02:00";

export function getLaunchTimestampMs(): number {
  return Date.parse(LAUNCH_ISO);
}

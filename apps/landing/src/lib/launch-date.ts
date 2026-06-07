/** Launch moment: 1 June 2026, start of day (Europe/Skopje). */
export const LAUNCH_ISO = "2026-06-12T00:00:00+02:00";

export function getLaunchTimestampMs(): number {
  return Date.parse(LAUNCH_ISO);
}

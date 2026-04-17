/** Launch moment: 20 May, start of day (Europe/Skopje). */
export const LAUNCH_ISO = "2026-05-20T00:00:00+02:00";

export function getLaunchTimestampMs(): number {
  return Date.parse(LAUNCH_ISO);
}

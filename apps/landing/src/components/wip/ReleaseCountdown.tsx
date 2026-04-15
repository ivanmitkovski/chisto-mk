"use client";

import { useEffect, useState } from "react";
import { getLaunchTimestampMs } from "@/lib/launch-date";
import type { WipDictionary } from "@/i18n/dictionaries";
import styles from "@/app/wip.module.css";

const LAUNCH_AT = getLaunchTimestampMs();

function pad2(n: number) {
  return n.toString().padStart(2, "0");
}

type Props = Pick<
  WipDictionary,
  | "countdownDays"
  | "countdownHours"
  | "countdownMinutes"
  | "countdownSeconds"
  | "countdownAria"
  | "liveMessage"
  | "countdownLoadingStatus"
>;

export function ReleaseCountdown(props: Props) {
  const {
    countdownDays,
    countdownHours,
    countdownMinutes,
    countdownSeconds,
    countdownAria,
    liveMessage,
    countdownLoadingStatus,
  } = props;

  const [now, setNow] = useState<number | null>(null);

  useEffect(() => {
    setNow(Date.now());
    const id = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(id);
  }, []);

  if (now === null) {
    return (
      <div
        className={styles.countdown}
        role="status"
        aria-live="polite"
        aria-busy="true"
        aria-label={countdownLoadingStatus}
      >
        {[
          { key: "d", label: countdownDays },
          { key: "h", label: countdownHours },
          { key: "m", label: countdownMinutes },
          { key: "s", label: countdownSeconds },
        ].map(({ key, label }) => (
          <div key={key} className={styles.countdownUnit} aria-hidden>
            <span className={styles.countdownValue}>…</span>
            <span className={styles.countdownLabel}>{label}</span>
          </div>
        ))}
      </div>
    );
  }

  const diff = Math.max(0, LAUNCH_AT - now);
  if (diff === 0) {
    return (
      <p className={styles.countdownLive} role="status" aria-live="polite">
        {liveMessage}
      </p>
    );
  }

  const days = Math.floor(diff / 86400000);
  const hours = Math.floor((diff % 86400000) / 3600000);
  const minutes = Math.floor((diff % 3600000) / 60000);
  const seconds = Math.floor((diff % 60000) / 1000);

  const units = [
    { label: countdownDays, value: String(days) },
    { label: countdownHours, value: pad2(hours) },
    { label: countdownMinutes, value: pad2(minutes) },
    { label: countdownSeconds, value: pad2(seconds) },
  ];

  const fullLabel = `${countdownAria}: ${days} ${countdownDays}, ${hours} ${countdownHours}, ${minutes} ${countdownMinutes}, ${seconds} ${countdownSeconds}`;

  return (
    <div className={styles.countdown} role="group" aria-label={fullLabel}>
      {units.map((u) => (
        <div key={u.label} className={styles.countdownUnit}>
          <span className={styles.countdownValue} aria-hidden>
            {u.value}
          </span>
          <span className={styles.countdownLabel} aria-hidden>
            {u.label}
          </span>
        </div>
      ))}
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { formatNotificationRelativeTimeFromIso } from '@/lib/format-notification-relative-time';

type NotificationRelativeTimeProps = {
  createdAt?: string;
  fallbackLabel: string;
  className?: string;
};

export function NotificationRelativeTime({
  createdAt,
  fallbackLabel,
  className,
}: NotificationRelativeTimeProps) {
  const [label, setLabel] = useState(fallbackLabel);

  useEffect(() => {
    const update = () => {
      setLabel(formatNotificationRelativeTimeFromIso(createdAt, fallbackLabel));
    };
    update();
    if (!createdAt) {
      return;
    }
    const id = window.setInterval(update, 30_000);
    return () => window.clearInterval(id);
  }, [createdAt, fallbackLabel]);

  if (createdAt) {
    return (
      <time dateTime={createdAt} className={className}>
        {label}
      </time>
    );
  }

  return <span className={className}>{label}</span>;
}

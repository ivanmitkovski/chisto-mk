import Link from "next/link";
import type { SiteShareEvent } from "./types";

type ShareEventsListProps = {
  title: string;
  participantsLabel: string;
  events: SiteShareEvent[];
  formatSchedule: (iso: string) => string;
  eventHref: (id: string) => string;
};

export function ShareEventsList({
  title,
  participantsLabel,
  events,
  formatSchedule,
  eventHref,
}: ShareEventsListProps) {
  if (events.length === 0) return null;
  return (
    <section aria-labelledby="share-events-heading">
      <h2 id="share-events-heading" className="text-base font-semibold text-ink">
        {title}
      </h2>
      <ul className="mt-3 space-y-3">
        {events.map((event) => {
          const max = event.maxParticipants;
          const countLabel =
            max != null && max > 0
              ? `${event.participantCount}/${max} ${participantsLabel}`
              : `${event.participantCount} ${participantsLabel}`;
          return (
            <li key={event.id}>
              <Link
                href={eventHref(event.id)}
                className="block rounded-2xl bg-surface-muted px-4 py-3 transition-colors hover:bg-[#E8EAEF] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              >
                <p className="font-semibold text-ink">{event.title}</p>
                <p className="mt-1 text-sm text-ink-secondary">{formatSchedule(event.scheduledAt)}</p>
                <p className="mt-0.5 text-sm text-ink-muted">
                  {event.city} · {countLabel}
                </p>
              </Link>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

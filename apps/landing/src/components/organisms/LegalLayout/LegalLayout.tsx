import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { LegalRichBody } from "@/lib/legal/legal-rich-body";

export type LegalSection = { title: string; body: string };

export function LegalLayout({
  badge,
  title,
  lastUpdatedLabel,
  lastUpdated,
  effectiveDateLabel,
  effectiveDate,
  noticeTitle,
  noticeBody,
  sections,
}: {
  badge: string;
  title: string;
  lastUpdatedLabel: string;
  lastUpdated: string;
  effectiveDateLabel?: string;
  effectiveDate?: string;
  noticeTitle: string;
  noticeBody: string;
  sections: LegalSection[];
}) {
  return (
    <Section className="relative overflow-hidden mesh-section-faq">
      <div
        className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-20"
        aria-hidden
      />
      <Container className="relative z-10 max-w-[min(42rem,calc(100%-1.5rem))] pb-8 md:pb-10">
        <Badge>{badge}</Badge>
        <h1 className="mt-4 text-balance text-section-title font-bold tracking-tight text-gray-900">
          {title}
        </h1>
        <div className="mt-4 flex flex-col gap-1.5 text-sm text-gray-500 sm:flex-row sm:flex-wrap sm:items-baseline sm:gap-x-10 sm:gap-y-1">
          <p>
            <span className="font-medium text-gray-600">{lastUpdatedLabel}</span>{" "}
            <span className="tabular-nums text-gray-700">{lastUpdated}</span>
          </p>
          {effectiveDateLabel?.trim() && effectiveDate?.trim() ? (
            <p>
              <span className="font-medium text-gray-600">{effectiveDateLabel}</span>{" "}
              <span className="tabular-nums text-gray-700">{effectiveDate}</span>
            </p>
          ) : null}
        </div>

        <div
          className="mt-8 rounded-2xl border border-amber-200/90 bg-amber-50/90 p-5 text-amber-950 shadow-sm shadow-amber-900/5 md:p-6"
          role="note"
        >
          <p className="text-sm font-semibold tracking-tight text-amber-950">{noticeTitle}</p>
          <div className="mt-3 text-sm leading-relaxed text-amber-950/95">
            <LegalRichBody
              body={noticeBody}
              className="flex flex-col gap-3"
              linkClassName="font-semibold text-amber-900 underline decoration-amber-700/45 underline-offset-2 transition-colors hover:decoration-amber-800"
            />
          </div>
        </div>

        <div className="mt-14 flex flex-col gap-14 md:mt-16 md:gap-16">
          {sections.map((s, i) => (
            <section
              key={i}
              className="scroll-mt-28 border-b border-gray-200/70 pb-14 last:border-0 last:pb-0 md:scroll-mt-32 md:pb-16"
            >
              <h2 className="text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">
                {s.title}
              </h2>
              <div className="mt-5 text-[0.9375rem] md:mt-6 md:text-base">
                <LegalRichBody body={s.body} />
              </div>
            </section>
          ))}
        </div>
      </Container>
    </Section>
  );
}

import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { LegalPageNav } from "@/components/molecules/LegalPageNav";
import { LegalRichBody } from "@/lib/legal/legal-rich-body";

export type LegalSection = { title: string; body: string };

export function LegalLayout({
  badge,
  title,
  lastUpdatedLabel,
  lastUpdated,
  effectiveDateLabel,
  effectiveDate,
  sections,
  showPageNav = true,
}: {
  badge: string;
  title: string;
  lastUpdatedLabel: string;
  lastUpdated: string;
  effectiveDateLabel?: string;
  effectiveDate?: string;
  sections: LegalSection[];
  showPageNav?: boolean;
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

        {showPageNav ? <LegalPageNav className="mt-14 md:mt-16" /> : null}
      </Container>
    </Section>
  );
}

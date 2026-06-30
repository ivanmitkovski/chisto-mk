import { getTranslations } from "next-intl/server";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { PageLoadingSkeleton } from "@/components/molecules/PageLoadingSkeleton";

export default async function HelpHubLoading() {
  const t = await getTranslations("helpCentre");
  return (
    <Section className="relative overflow-hidden mesh-section-how" aria-busy="true">
      <Container className="relative z-10 py-16">
        <PageLoadingSkeleton srLabel={t("loadingLabel")} lines={6} />
      </Container>
    </Section>
  );
}

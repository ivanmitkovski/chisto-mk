import { MarketingAtmosphere } from "@/components/layout/MarketingAtmosphere/MarketingAtmosphere";
import { ScrollToTopButton } from "@/components/layout/ScrollToTopButton";
import { CookieConsentChrome } from "@/components/organisms/CookieConsent";
import { Header } from "@/components/organisms/Header";
import { Footer } from "@/components/organisms/Footer";
import { CookieConsentProvider } from "@/contexts/CookieConsentContext";

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <CookieConsentProvider>
      <Header />
      <main className="relative overflow-x-clip">
        <MarketingAtmosphere />
        <div className="relative z-10">{children}</div>
      </main>
      <Footer />
      <ScrollToTopButton />
      <CookieConsentChrome />
    </CookieConsentProvider>
  );
}

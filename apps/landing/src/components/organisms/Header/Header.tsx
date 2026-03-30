"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Logo } from "@/components/atoms/Logo";
import { Button } from "@/components/atoms/Button";
import { NavItem } from "@/components/molecules/NavItem";
import { LanguageSelector } from "@/components/molecules/LanguageSelector";
import { MobileMenu } from "@/components/organisms/Header/MobileMenu";
import { cn } from "@/lib/utils/cn";

const NAV_HREFS = ["/", "/about", "/news", "/press", "/contact"] as const;
const NAV_KEYS = ["home", "about", "news", "press", "contact"] as const;

export function Header() {
  const [scrolled, setScrolled] = useState(false);
  const tNav = useTranslations("nav");
  const tCommon = useTranslations("common");

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-50 border-b transition-[background-color,box-shadow,backdrop-filter,border-color] duration-300",
        scrolled
          ? "border-black/[0.06] border-b-primary/10 bg-white/90 shadow-[0_10px_40px_rgba(0,0,0,0.07),0_1px_0_rgba(0,217,142,0.12)] backdrop-blur-xl backdrop-saturate-150"
          : "border-transparent bg-white/75 shadow-[0_1px_0_rgba(0,0,0,0.04)] backdrop-blur-md backdrop-saturate-125",
      )}
    >
      <Container className="flex h-[4.25rem] items-center justify-between md:grid md:h-20 md:grid-cols-[1fr_auto_1fr] md:items-center">
        <Logo className="shrink-0" />

        <nav
          className="hidden items-center justify-center gap-5 lg:gap-7 md:flex"
          aria-label="Main navigation"
        >
          {NAV_HREFS.map((href, i) => (
            <NavItem key={href} href={href} label={tNav(NAV_KEYS[i])} />
          ))}
        </nav>

        <div className="flex shrink-0 items-center justify-end gap-2 md:gap-3">
          <LanguageSelector />
          <Button size="sm" className="hidden px-7 shadow-sm shadow-primary/20 md:inline-flex">
            {tCommon("download")}
          </Button>
          <div className="md:hidden">
            <MobileMenu />
          </div>
        </div>
      </Container>
    </header>
  );
}

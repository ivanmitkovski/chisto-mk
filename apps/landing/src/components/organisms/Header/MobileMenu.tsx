"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { Menu, X } from "lucide-react";
import { useRef, useState } from "react";
import { useTranslations } from "next-intl";
import { NavItem } from "@/components/molecules/NavItem";
import { DownloadCTA } from "@/components/molecules/DownloadCTA";
import { visibleMarketingNavItems } from "@/config/launch";
import {
  isOnHomePage,
  navigateToDownloadFromPath,
  scrollToDownloadOnHome,
  useDownloadNavigation,
} from "@/lib/navigation/download-navigation";
import styles from "./mobile-menu.module.css";

export function MobileMenu() {
  const [open, setOpen] = useState(false);
  const pendingDownload = useRef(false);
  const tNav = useTranslations("nav");
  const tCommon = useTranslations("common");
  const navItems = visibleMarketingNavItems();
  const { pathname, router } = useDownloadNavigation();

  function handleOpenChange(nextOpen: boolean) {
    setOpen(nextOpen);
    if (nextOpen || !pendingDownload.current) return;
    pendingDownload.current = false;
    if (!isOnHomePage(pathname)) {
      navigateToDownloadFromPath(pathname, router);
      return;
    }
    scrollToDownloadOnHome(true);
  }

  function handleDownloadNavigate() {
    pendingDownload.current = isOnHomePage(pathname);
    setOpen(false);
  }

  return (
    <Dialog.Root open={open} onOpenChange={handleOpenChange}>
      <Dialog.Trigger asChild>
        <button
          type="button"
          className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-gray-900 transition-colors hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 md:hidden"
          aria-label={tNav("menu")}
          aria-expanded={open}
        >
          <Menu className="h-6 w-6" strokeWidth={1.75} />
        </button>
      </Dialog.Trigger>

      <Dialog.Portal>
        <Dialog.Overlay className={styles.overlay} />
        <Dialog.Content className={styles.panel} aria-describedby={undefined}>
          <div className="flex shrink-0 items-center justify-between border-b border-gray-100 pb-4">
            <Dialog.Title className="text-sm font-semibold uppercase tracking-wider text-gray-500">
              {tNav("menu")}
            </Dialog.Title>
            <Dialog.Close asChild>
              <button
                type="button"
                className="inline-flex h-9 w-9 items-center justify-center rounded-lg text-gray-600 transition-colors hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                aria-label={tCommon("close")}
              >
                <X className="h-5 w-5" strokeWidth={1.75} />
              </button>
            </Dialog.Close>
          </div>
          <nav
            className="mt-8 flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto overscroll-contain"
            aria-label={tNav("mobileAria")}
          >
            {navItems.map((item) => (
              <div key={item.href} className="shrink-0 rounded-lg py-1">
                <NavItem
                  href={item.href}
                  label={tNav(item.key)}
                  onClick={() => setOpen(false)}
                />
              </div>
            ))}
          </nav>
          <div className="mt-auto shrink-0 border-t border-gray-100 pt-6">
            <DownloadCTA
              size="md"
              className="w-full shadow-md shadow-primary/25"
              onNavigate={handleDownloadNavigate}
              analyticsSource="mobile_menu"
            />
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

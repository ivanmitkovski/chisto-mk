"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { Menu, X } from "lucide-react";
import { useState } from "react";
import { useTranslations } from "next-intl";
import { NavItem } from "@/components/molecules/NavItem";
import { Button } from "@/components/atoms/Button";

const NAV_HREFS = ["/", "/about", "/news", "/press", "/contact"] as const;
const NAV_KEYS = ["home", "about", "news", "press", "contact"] as const;

export function MobileMenu() {
  const [open, setOpen] = useState(false);
  const tNav = useTranslations("nav");
  const tCommon = useTranslations("common");

  return (
    <Dialog.Root open={open} onOpenChange={setOpen}>
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
        <Dialog.Overlay className="fixed inset-0 z-50 bg-black/45 backdrop-blur-[2px] data-[state=open]:animate-fade-in" />
        <Dialog.Content
          className="fixed inset-y-0 right-0 z-50 flex w-[min(100vw-1.5rem,20rem)] flex-col border-l border-gray-200/80 bg-white p-6 shadow-[-12px_0_40px_rgba(0,0,0,0.08)] data-[state=open]:animate-slide-up focus:outline-none"
          aria-describedby={undefined}
        >
          <div className="flex items-center justify-between border-b border-gray-100 pb-4">
            <Dialog.Title className="text-sm font-semibold uppercase tracking-wider text-gray-500">
              {tNav("menu")}
            </Dialog.Title>
            <Dialog.Close asChild>
              <button
                type="button"
                className="inline-flex h-9 w-9 items-center justify-center rounded-lg text-gray-600 transition-colors hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                aria-label="Close"
              >
                <X className="h-5 w-5" strokeWidth={1.75} />
              </button>
            </Dialog.Close>
          </div>
          <nav className="mt-8 flex flex-col gap-1" aria-label="Mobile navigation">
            {NAV_HREFS.map((href, i) => (
              <div key={href} className="rounded-lg py-1">
                <NavItem
                  href={href}
                  label={tNav(NAV_KEYS[i])}
                  onClick={() => setOpen(false)}
                />
              </div>
            ))}
          </nav>
          <div className="mt-auto border-t border-gray-100 pt-6">
            <Button className="w-full shadow-md shadow-primary/25" size="md">
              {tCommon("download")}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

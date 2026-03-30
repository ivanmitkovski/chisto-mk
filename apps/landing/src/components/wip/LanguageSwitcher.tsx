"use client";

import { useRouter, usePathname } from "next/navigation";
import {
  useCallback,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { languageOptionLabels, locales, type Locale } from "@/i18n/config";
import styles from "@/app/wip.module.css";

type Props = {
  currentLocale: Locale;
  /** Accessible name for the language navigation region. */
  ariaLabel: string;
};

export function LanguageSwitcher({ currentLocale, ariaLabel }: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const baseId = useId();
  const buttonRef = useRef<HTMLButtonElement>(null);
  const wrapRef = useRef<HTMLDivElement>(null);

  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const [panelBox, setPanelBox] = useState<{
    top: number;
    left: number;
    width: number;
  } | null>(null);

  const listboxId = `${baseId}-listbox`;
  const currentIndex = Math.max(0, locales.indexOf(currentLocale));

  const updatePanelPosition = useCallback(() => {
    const el = buttonRef.current;
    if (!el || typeof window === "undefined") return;
    const r = el.getBoundingClientRect();
    const width = Math.max(r.width, 200);
    const rawLeft = r.left;
    const left = Math.min(Math.max(8, rawLeft), Math.max(8, window.innerWidth - width - 8));
    setPanelBox({
      top: r.bottom + 8,
      left,
      width,
    });
  }, []);

  useLayoutEffect(() => {
    if (!open) return;
    updatePanelPosition();
    const onWin = () => updatePanelPosition();
    window.addEventListener("resize", onWin);
    window.addEventListener("scroll", onWin, true);
    return () => {
      window.removeEventListener("resize", onWin);
      window.removeEventListener("scroll", onWin, true);
    };
  }, [open, updatePanelPosition]);

  useEffect(() => {
    if (!open) return;
    setActiveIndex(currentIndex);
  }, [open, currentIndex]);

  useEffect(() => {
    if (!open) return;
    const onDocPointer = (e: MouseEvent | PointerEvent) => {
      const t = e.target as Node;
      if (wrapRef.current?.contains(t)) return;
      setOpen(false);
    };
    document.addEventListener("pointerdown", onDocPointer, true);
    return () => document.removeEventListener("pointerdown", onDocPointer, true);
  }, [open]);

  const navigateTo = useCallback(
    (next: Locale) => {
      if (next === currentLocale) {
        setOpen(false);
        return;
      }
      const rest = pathname.split("/").slice(2).join("/");
      const suffix = rest ? `/${rest}` : "";
      router.push(`/${next}${suffix}`);
      setOpen(false);
    },
    [currentLocale, pathname, router],
  );

  const selectIndex = useCallback(
    (index: number) => {
      const loc = locales[index];
      if (loc) navigateTo(loc);
    },
    [navigateTo],
  );

  const onButtonKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === "Escape") {
      e.preventDefault();
      setOpen(false);
      return;
    }

    if (!open && (e.key === "Enter" || e.key === " ")) {
      e.preventDefault();
      setOpen(true);
      setActiveIndex(currentIndex);
      return;
    }

    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (!open) {
        setOpen(true);
        setActiveIndex(currentIndex);
        return;
      }
      setActiveIndex((i) => (i + 1) % locales.length);
      return;
    }

    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (!open) {
        setOpen(true);
        setActiveIndex(currentIndex);
        return;
      }
      setActiveIndex((i) => (i - 1 + locales.length) % locales.length);
      return;
    }

    if (e.key === "Home" && open) {
      e.preventDefault();
      setActiveIndex(0);
      return;
    }

    if (e.key === "End" && open) {
      e.preventDefault();
      setActiveIndex(locales.length - 1);
      return;
    }

    if ((e.key === "Enter" || e.key === " ") && open) {
      e.preventDefault();
      selectIndex(activeIndex);
    }
  };

  const activeOptionId = `${baseId}-opt-${locales[activeIndex]}`;

  return (
    <nav className={styles.langNav} aria-label={ariaLabel}>
      <div ref={wrapRef} className={styles.langDropdown}>
        <button
          ref={buttonRef}
          id={`${baseId}-button`}
          type="button"
          role="combobox"
          aria-autocomplete="none"
          className={styles.langDropdownButton}
          aria-haspopup="listbox"
          aria-expanded={open}
          aria-controls={listboxId}
          aria-activedescendant={open ? activeOptionId : undefined}
          aria-label={`${ariaLabel}: ${languageOptionLabels[currentLocale].toLowerCase()}`}
          onClick={() => {
            setOpen((v) => !v);
          }}
          onKeyDown={onButtonKeyDown}
        >
          <span className={styles.langDropdownValue}>
            {languageOptionLabels[currentLocale]}
          </span>
          <span className={styles.langDropdownChevron} aria-hidden />
        </button>

        {open && panelBox ? (
          <div
            id={listboxId}
            role="listbox"
            aria-label={ariaLabel}
            className={styles.langDropdownPanel}
            style={{
              position: "fixed",
              top: panelBox.top,
              left: panelBox.left,
              width: panelBox.width,
              zIndex: 100,
            }}
          >
            {locales.map((loc, index) => {
              const selected = loc === currentLocale;
              const active = index === activeIndex;
              return (
                <button
                  key={loc}
                  id={`${baseId}-opt-${loc}`}
                  type="button"
                  role="option"
                  tabIndex={-1}
                  aria-selected={selected}
                  data-active={active ? "" : undefined}
                  className={styles.langDropdownOption}
                  onMouseEnter={() => setActiveIndex(index)}
                  onClick={() => navigateTo(loc)}
                >
                  <span className={styles.langDropdownOptionLabel}>{languageOptionLabels[loc]}</span>
                </button>
              );
            })}
          </div>
        ) : null}
      </div>
    </nav>
  );
}

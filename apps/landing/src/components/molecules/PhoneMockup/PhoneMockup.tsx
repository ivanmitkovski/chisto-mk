import { cn } from "@/lib/utils/cn";

interface PhoneMockupProps {
  children: React.ReactNode;
  className?: string;
}

/** iPhone-style device frame (see `.phone-mockup--iphone` in globals.css). */
export function PhoneMockup({ children, className }: PhoneMockupProps) {
  return (
    <div
      className={cn(
        "phone-mockup phone-mockup--iphone shadow-[var(--shadow-phone)]",
        className,
      )}
      aria-hidden
    >
      <div className="phone-mockup__frame">
        <span className="phone-mockup__button phone-mockup__button--mute" />
        <span className="phone-mockup__button phone-mockup__button--volume-up" />
        <span className="phone-mockup__button phone-mockup__button--volume-down" />
        <span className="phone-mockup__button phone-mockup__button--power" />
        <div className="phone-mockup__screen">{children}</div>
      </div>
    </div>
  );
}

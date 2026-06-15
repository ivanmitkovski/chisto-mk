import { cn } from "@/lib/utils/cn";

interface PhoneMockupProps {
  children: React.ReactNode;
  className?: string;
}

export function PhoneMockup({ children, className }: PhoneMockupProps) {
  return (
    <div
      className={cn(
        "relative rounded-[3rem]", // matches bezel so shadows on this wrapper stay rounded
        className,
      )}
    >
      <div
        className={cn(
          "relative rounded-[3rem] bg-black p-3",
          "shadow-[0_16px_44px_rgba(0,0,0,0.09),0_6px_20px_rgba(0,0,0,0.05),0_4px_16px_rgba(0,217,142,0.04)]",
          "ring-1 ring-white/10",
        )}
      >
        <div className="relative overflow-hidden rounded-[2.5rem] bg-white ring-1 ring-black/5">
          {children}
        </div>
      </div>
    </div>
  );
}

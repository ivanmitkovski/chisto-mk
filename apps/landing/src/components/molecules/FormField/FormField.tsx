import { cn } from "@/lib/utils/cn";

interface FormFieldProps {
  label: string;
  children: React.ReactNode;
  className?: string;
}

export function FormField({ label, children, className }: FormFieldProps) {
  return (
    <div className={cn("w-full", className)}>
      <label className="mb-2 block text-xs font-semibold uppercase tracking-[0.08em] text-gray-800">
        {label}
      </label>
      {children}
    </div>
  );
}

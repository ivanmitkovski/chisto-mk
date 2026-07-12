import { forwardRef, InputHTMLAttributes, useId } from "react";
import { cn } from "@/lib/utils/cn";
import { formControlClassName, formControlErrorClassName } from "./form-control";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: string | undefined;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, error, id: idProp, ...props }, ref) => {
    const autoId = useId();
    const id = idProp ?? autoId;
    const errorId = error ? `${id}-error` : undefined;

    return (
      <div className="w-full">
        <input
          ref={ref}
          id={id}
          aria-invalid={error ? true : undefined}
          aria-describedby={errorId}
          className={cn(
            formControlClassName,
            error && formControlErrorClassName,
            className,
          )}
          {...props}
        />
        {error ? (
          <p id={errorId} className="mt-1.5 text-sm text-red-500" role="alert">
            {error}
          </p>
        ) : null}
      </div>
    );
  },
);

Input.displayName = "Input";

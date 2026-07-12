import { forwardRef, TextareaHTMLAttributes, useId } from "react";
import { cn } from "@/lib/utils/cn";
import { formControlClassName, formControlErrorClassName } from "./form-control";

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: string | undefined;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, error, id: idProp, ...props }, ref) => {
    const autoId = useId();
    const id = idProp ?? autoId;
    const errorId = error ? `${id}-error` : undefined;

    return (
      <div className="w-full">
        <textarea
          ref={ref}
          id={id}
          aria-invalid={error ? true : undefined}
          aria-describedby={errorId}
          className={cn(
            formControlClassName,
            "min-h-[8.5rem] resize-y",
            error && formControlErrorClassName,
            className,
          )}
          rows={5}
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

Textarea.displayName = "Textarea";

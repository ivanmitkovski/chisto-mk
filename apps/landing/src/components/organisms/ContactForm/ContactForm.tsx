"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { Button } from "@/components/atoms/Button";
import { Input } from "@/components/atoms/Input";
import { Textarea } from "@/components/atoms/Input/Textarea";
import { FormField } from "@/components/molecules/FormField";
import { SocialIcon } from "@/components/molecules/SocialIcon";
import { submitContactForm } from "@/app/actions/contact";
import type { ContactFormData, FieldError } from "@/lib/utils/validators";

function fieldLabel(field: keyof ContactFormData, tc: (key: string) => string) {
  switch (field) {
    case "fullName":
      return tc("fullName");
    case "phone":
      return tc("phone");
    case "email":
      return tc("email");
    case "message":
      return tc("message");
    default:
      return field;
  }
}

function translateFieldError(err: FieldError, te: (key: string, values?: Record<string, string>) => string, tc: (key: string) => string) {
  if (err.code === "required") {
    if (err.field === "email") return te("emailRequired");
    if (err.field === "phone") return te("phoneRequired");
    return te("requiredNamed", { label: fieldLabel(err.field, tc) });
  }
  if (err.code === "invalidEmail") return te("emailInvalid");
  if (err.code === "invalidPhone") return te("phoneInvalid");
  return te("required");
}

export function ContactForm() {
  const [status, setStatus] = useState<"idle" | "loading" | "success">("idle");
  const [errors, setErrors] = useState<FieldError[]>([]);
  const [serverError, setServerError] = useState(false);
  const tc = useTranslations("contact");
  const te = useTranslations("errors");
  const tCommon = useTranslations("common");
  const tp = useTranslations("contact.placeholders");

  function getError(field: string) {
    const err = errors.find((e) => e.field === field);
    if (!err) return undefined;
    return translateFieldError(err, te, tc);
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("loading");
    setErrors([]);
    setServerError(false);

    const fd = new FormData(e.currentTarget);
    const result = await submitContactForm({
      fullName: fd.get("fullName") as string,
      phone: fd.get("phone") as string,
      email: fd.get("email") as string,
      message: fd.get("message") as string,
    });

    if (result.ok) {
      setStatus("success");
      (e.target as HTMLFormElement).reset();
    } else if (result.errors?.length) {
      setErrors(result.errors);
      setStatus("idle");
    } else if (result.serverError) {
      setServerError(true);
      setStatus("idle");
    }
  }

  return (
    <Section className="relative overflow-hidden mesh-section-how">
      <div
        className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-25 [mask-image:linear-gradient(to_bottom,transparent,black_20%,black_80%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_20%,black_80%,transparent)]"
        aria-hidden
      />
      <Container className="relative z-10">
        <div className="flex flex-col gap-8 md:flex-row md:items-start md:justify-between md:gap-12">
          <div className="max-w-copy">
            <p className="text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{tc("kicker")}</p>
            <h1 className="mt-3 text-section-title font-bold text-gray-900">{tc("title")}</h1>
          </div>
          <div className="flex gap-2 md:flex-col md:gap-3 md:pt-1">
            <SocialIcon platform="facebook" />
            <SocialIcon platform="instagram" />
          </div>
        </div>

        {status === "success" ? (
          <div className="mt-12 rounded-3xl border border-primary/15 bg-primary/8 p-10 text-center shadow-sm md:mt-14">
            <p className="text-lg font-semibold text-primary">{tc("successTitle")}</p>
            <p className="mt-2 text-gray-600">{tc("successBody")}</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="mt-12 md:mt-14">
            <div className="grid gap-6 sm:gap-8 md:grid-cols-3">
              <FormField label={tc("fullName")}>
                <Input
                  name="fullName"
                  placeholder={tp("fullName")}
                  autoComplete="name"
                  error={getError("fullName")}
                />
              </FormField>
              <FormField label={tc("phone")}>
                <Input
                  name="phone"
                  type="tel"
                  placeholder={tp("phone")}
                  autoComplete="tel"
                  error={getError("phone")}
                />
              </FormField>
              <FormField label={tc("email")}>
                <Input
                  name="email"
                  type="email"
                  placeholder={tp("email")}
                  autoComplete="email"
                  error={getError("email")}
                />
              </FormField>
            </div>

            <div className="mt-8">
              <FormField label={tc("message")}>
                <Textarea name="message" placeholder={tp("message")} error={getError("message")} />
              </FormField>
            </div>

            <div className="mt-10 space-y-3">
              {serverError && <p className="text-sm text-red-500">{tc("submitError")}</p>}
              <Button type="submit" size="lg" className="shadow-md shadow-primary/25" disabled={status === "loading"}>
                {tCommon("send")}
              </Button>
            </div>
          </form>
        )}
      </Container>
    </Section>
  );
}

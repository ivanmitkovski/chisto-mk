import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, type Locale } from "@/i18n/config";
import styles from "../../legal.module.css";

const COPY: Record<Locale, { title: string; sections: string[]; contact: string }> = {
  mk: {
    title: "Политика на приватност",
    sections: [
      "Chisto.mk ги обработува личните податоци за да овозможи пријава на загадување, учество на акции и комуникација со заедницата.",
      "Можете да побарате извоз на податоци или бришење на сметка од апликацијата (Профил → Поставки) или на privacy@chisto.mk.",
      "Сметките во статус избришано се анонимизирани; по 30-дневна грејс период се трајно бришат идентификаторите.",
    ],
    contact: "Контакт: privacy@chisto.mk",
  },
  en: {
    title: "Privacy policy",
    sections: [
      "Chisto.mk processes personal data to enable pollution reporting, cleanup participation, and community notifications.",
      "You can export your data or delete your account from the mobile app (Profile → Settings) or by emailing privacy@chisto.mk.",
      "Deleted accounts are anonymized immediately; after a 30-day grace period we purge remaining identifiers.",
    ],
    contact: "Contact: privacy@chisto.mk",
  },
  sq: {
    title: "Politika e privatësisë",
    sections: [
      "Chisto.mk përpunon të dhënat personale për raportimin e ndotjes dhe pjesëmarrjen në aktivitete.",
      "Eksporti i të dhënave dhe fshirja e llogarisë bëhen nga aplikacioni (Profili → Cilësimet) ose në privacy@chisto.mk.",
      "Llogaritë e fshira anonimizohen; pas 30 ditësh identifikuesit fshihen përfundimisht.",
    ],
    contact: "Kontakt: privacy@chisto.mk",
  },
};

export default async function PrivacyPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale: localeParam } = await params;
  if (!isLocale(localeParam)) notFound();
  const locale = localeParam as Locale;
  const copy = COPY[locale];

  return (
    <main className={styles.page}>
      <article className={styles.card}>
        <h1>{copy.title}</h1>
        {copy.sections.map((p) => (
          <p key={p}>{p}</p>
        ))}
        <p>{copy.contact}</p>
        <p>
          <Link href={`/${locale}/account-deletion`}>
            {locale === "mk" ? "Бришење на сметка" : locale === "sq" ? "Fshirja e llogarisë" : "Account deletion"}
          </Link>
        </p>
      </article>
    </main>
  );
}

import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, type Locale } from "@/i18n/config";
import styles from "../../legal.module.css";

const COPY: Record<
  Locale,
  { title: string; intro: string; steps: string[]; privacy: string }
> = {
  mk: {
    title: "Бришење на сметка",
    intro:
      "Можете трајно да ја избришете вашата Chisto.mk сметка од мобилната апликација. Оваа страница е за корисници и за барањата на продавниците за апликации (Apple / Google).",
    steps: [
      "Отворете ја апликацијата Chisto.mk и најавете се.",
      "Одете на Профил → Поставки → Избриши сметка.",
      "Потврдете го бришењето. Сесиите и push токените се поништуваат; личните податоци се анонимизираат.",
      "За извоз на податоци пред бришење: Профил → Поставки → Извоз на мои податоци (или контактирајте privacy@chisto.mk).",
    ],
    privacy: "Политика на приватност",
  },
  en: {
    title: "Account deletion",
    intro:
      "You can permanently delete your Chisto.mk account from the mobile app. This page is for users and for Apple App Store / Google Play account-deletion requirements.",
    steps: [
      "Open the Chisto.mk app and sign in.",
      "Go to Profile → Settings → Delete account.",
      "Confirm deletion. Sessions and push tokens are revoked; personal data is anonymized on our servers.",
      "To export your data before deletion, use Profile → Settings → Export my data, or email privacy@chisto.mk.",
    ],
    privacy: "Privacy policy",
  },
  sq: {
    title: "Fshirja e llogarisë",
    intro:
      "Mund ta fshini përgjithmonë llogarinë tuaj Chisto.mk nga aplikacioni mobil. Kjo faqe plotëson kërkesat e Apple / Google për fshirjen e llogarisë.",
    steps: [
      "Hapni aplikacionin Chisto.mk dhe identifikohuni.",
      "Shkoni te Profili → Cilësimet → Fshi llogarinë.",
      "Konfirmoni. Sesionet dhe tokenët push anulohen; të dhënat personale anonimizohen.",
      "Për eksport para fshirjes: Profili → Eksporto të dhënat, ose privacy@chisto.mk.",
    ],
    privacy: "Politika e privatësisë",
  },
  rom: {
    title: "Te xas amaro konto",
    intro:
      "Tu śaj te xas amaro Chisto.mk konto andar o mobilno app. Kado si va Apple thaj Google.",
    steps: [
      "Khul o Chisto.mk app thaj sign in.",
      "Jas Profile → Settings → Delete account.",
      "Confirm. Sessions thaj push tokens band, PII anonymized.",
    ],
    privacy: "Privacy policy",
  },
  sr: {
    title: "Брисање налога",
    intro:
      "Можете трајно обрисати Chisto.mk налог у мобилној апликацији. Ова страница је за Apple / Google захтеве за брисање налога.",
    steps: [
      "Отворите Chisto.mk апликацију и пријавите се.",
      "Идите на Профил → Подешавања → Обриши налог.",
      "Потврдите. Сесије и push токени се опозивају; лични подаци се анонимизују.",
      "За извоз података: Профил → Извоз података или privacy@chisto.mk.",
    ],
    privacy: "Политика приватности",
  },
};

type Props = { params: Promise<{ locale: string }> };

export default async function AccountDeletionPage({ params }: Props) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  const c = COPY[raw];

  return (
    <main className={styles.page} style={{ maxWidth: 640, margin: "0 auto", padding: "2rem" }}>
      <h1>{c.title}</h1>
      <p>{c.intro}</p>
      <ol>
        {c.steps.map((step) => (
          <li key={step}>{step}</li>
        ))}
      </ol>
      <p>
        <Link href={`/${raw}`}>← Chisto.mk</Link>
        {" · "}
        <a href="https://chisto.mk/privacy">{c.privacy}</a>
      </p>
    </main>
  );
}

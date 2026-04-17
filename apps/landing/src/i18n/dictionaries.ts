import type { Locale } from "./config";

export type WipDictionary = {
  metaTitle: string;
  metaDescription: string;
  launchDate: string;
  badge: string;
  lead: string;
  metaStrong: string;
  metaLine: string;
  footer: string;
  countdownDays: string;
  countdownHours: string;
  countdownMinutes: string;
  countdownSeconds: string;
  countdownAria: string;
  liveMessage: string;
  /** Accessible label for the language dropdown. */
  languageSelectAria: string;
  notifyTitle: string;
  notifyDescription: string;
  notifyPlaceholder: string;
  notifySubmit: string;
  notifySuccess: string;
  notifyErrorInvalid: string;
  /** Saving to the subscriber list failed (e.g. disk). */
  notifyErrorSave: string;
  /** Email is already on the list (server-side). */
  notifyAlreadySubscribed: string;
  /** Short transparency line (not legal advice). */
  notifyLegalHint: string;
  /** Consent checkbox for email updates (GDPR-style opt-in). */
  notifyConsentLabel: string;
  notifyErrorConsent: string;
  /** Opens the notifications signup modal. */
  notifyTriggerLabel: string;
  /** Shown on the trigger after the user has subscribed (this browser). */
  notifySubscribedTriggerLabel: string;
  /** While checking saved subscription state (avoids label flash after reload). */
  notifyTriggerLoadingLabel: string;
  /** Close control for the modal (visible label or aria-only). */
  notifyCloseLabel: string;
  /** Visible label for the email field (not placeholder-only). */
  notifyEmailLabel: string;
  /** Announced while the notify form is submitting. */
  notifySubmitPendingLabel: string;
  /** Skip link target: first focusable, jumps to main content. */
  skipToContent: string;
  /** Announced while the countdown is hydrating (client-only). */
  countdownLoadingStatus: string;
};

const mk: WipDictionary = {
  metaTitle: "Chisto.mk · 20 мај 2026",
  metaDescription:
    "Платформа за граѓанска екологија во Македонија. Пријавување, мапа и акции за чистење. Стартува на 20 мај 2026.",
  launchDate: "Стартува на 20 мај 2026",
  badge: "Во подготовка",
  lead:
    "Подготвуваме нов јавен простор за пријавување на еколошки проблеми, преглед на мапа и учество во акции за чистење низ Македонија.",
  metaStrong: "Граѓанска еколошка платформа",
  metaLine: "Целата платформа наскоро. Иста мисија, за зелена Македонија.",
  footer: "Македонија",
  countdownDays: "Денови",
  countdownHours: "Часови",
  countdownMinutes: "Минути",
  countdownSeconds: "Секунди",
  countdownAria: "Време до старт",
  liveMessage: "Сме онлајн. Истражете ја целата платформа.",
  languageSelectAria: "Јазик",
  notifyTitle: "Известувања",
  notifyDescription:
    "Оставете е-пошта и ќе ве известиме за стартот на платформата и за важни новости.",
  notifyPlaceholder: "ваша@епошта.mk",
  notifySubmit: "Пријави се",
  notifySuccess: "Ви благодариме! Ќе ве известиме наскоро со важни новости околу платформата.",
  notifyErrorInvalid: "Внесете важечка е-пошта.",
  notifyErrorSave: "Не успеа зачувувањето. Обидете се подоцна.",
  notifyAlreadySubscribed: "Оваа е-пошта веќе е пријавена.",
  notifyLegalHint: "Само за Chisto.mk. Не ја споделуваме со други.",
  notifyConsentLabel:
    "Се согласувам да добивам известувања од Chisto.mk на оваа е-пошта.",
  notifyErrorConsent: "Потребна е согласност за да продолжите.",
  notifyTriggerLabel: "Извести ме",
  notifyTriggerLoadingLabel: "Се вчитува…",
  notifySubscribedTriggerLabel: "Пријавени за известувања",
  notifyCloseLabel: "Затвори",
  notifyEmailLabel: "Е-пошта",
  notifySubmitPendingLabel: "Се зачувува…",
  skipToContent: "Прескокни кон главна содржина",
  countdownLoadingStatus: "Се вчитува тајмерот",
};

const en: WipDictionary = {
  metaTitle: "Chisto.mk · May 20, 2026",
  metaDescription:
    "Civic environmental platform for Macedonia. Report issues, explore the map, and join clean-ups. Launching May 20, 2026.",
  launchDate: "Launching May 20, 2026",
  badge: "Work in progress",
  lead:
    "We are preparing a new public space to report environmental issues, see them on a map, and join clean-up efforts across Macedonia.",
  metaStrong: "Civic environmental platform",
  metaLine: "Full platform soon. Same mission, for a green Macedonia.",
  footer: "Macedonia",
  countdownDays: "Days",
  countdownHours: "Hours",
  countdownMinutes: "Minutes",
  countdownSeconds: "Seconds",
  countdownAria: "Time until launch",
  liveMessage: "We are live. Explore the full platform.",
  languageSelectAria: "Language",
  notifyTitle: "Get notified",
  notifyDescription:
    "Drop your email and we’ll tell you when we launch and when there’s news worth sharing.",
  notifyPlaceholder: "you@example.com",
  notifySubmit: "Sign up",
  notifySuccess: "Thanks! We’ll email you with news about the platform.",
  notifyErrorInvalid: "Enter a valid email address.",
  notifyErrorSave: "Couldn't save your signup. Please try again.",
  notifyAlreadySubscribed: "This email is already registered.",
  notifyLegalHint: "Chisto.mk only. We don’t share your address.",
  notifyConsentLabel:
    "I agree to get Chisto.mk updates at this email address.",
  notifyErrorConsent: "Please accept the checkbox to continue.",
  notifyTriggerLabel: "Notify me",
  notifyTriggerLoadingLabel: "Loading…",
  notifySubscribedTriggerLabel: "You're subscribed",
  notifyCloseLabel: "Close",
  notifyEmailLabel: "Email",
  notifySubmitPendingLabel: "Saving…",
  skipToContent: "Skip to main content",
  countdownLoadingStatus: "Loading countdown",
};

const sq: WipDictionary = {
  metaTitle: "Chisto.mk · 20 maj 2026",
  metaDescription:
    "Platformë qytetare mjedisore për Maqedoninë. Raportoni, hartë dhe aksione pastrimi. Nis më 20 maj 2026.",
  launchDate: "Nis më 20 maj 2026",
  badge: "Në punë",
  lead:
    "Po përgatisim një hapësirë të re publike për të raportuar çështje mjedisore, t’i shihni në hartë dhe të bashkoheni në aksione pastrimi nëpër Maqedoni.",
  metaStrong: "Platformë qytetare mjedisore",
  metaLine: "Platforma e plotë së shpejti. E njëjta mision, për një Maqedoni të gjelbër.",
  footer: "Maqedoni",
  countdownDays: "Ditë",
  countdownHours: "Orë",
  countdownMinutes: "Minuta",
  countdownSeconds: "Sekonda",
  countdownAria: "Koha deri në nisje",
  liveMessage: "Jemi live. Eksploroni platformën e plotë.",
  languageSelectAria: "Gjuha",
  notifyTitle: "Njoftime",
  notifyDescription:
    "Lini email-in dhe do t'ju njoftojmë për nisjen e platformës dhe për lajme të rëndësishme.",
  notifyPlaceholder: "ju@shembull.com",
  notifySubmit: "Regjistrohu",
  notifySuccess: "Faleminderit! Do t'ju njoftojmë së shpejti me lajme të rëndësishme.",
  notifyErrorInvalid: "Shkruani një adresë email të vlefshme.",
  notifyErrorSave: "Nuk u ruajt. Provoni përsëri më vonë.",
  notifyAlreadySubscribed: "Kjo adresë email është tashmë e regjistruar.",
  notifyLegalHint: "Vetëm për Chisto.mk. Nuk e ndajmë adresën.",
  notifyConsentLabel:
    "Pranoj të marr njoftime nga Chisto.mk në këtë email.",
  notifyErrorConsent: "Duhet të pranoni kutizën për të vazhduar.",
  notifyTriggerLabel: "Njoftomë",
  notifyTriggerLoadingLabel: "Po ngarkohet…",
  notifySubscribedTriggerLabel: "I regjistruar për njoftime",
  notifyCloseLabel: "Mbyll",
  notifyEmailLabel: "Email",
  notifySubmitPendingLabel: "Po ruhet…",
  skipToContent: "Kalo te përmbajtja kryesore",
  countdownLoadingStatus: "Po ngarkohet numëruesi",
};

/** Romani (Latin script, Balkan varieties vary; refine with native speakers if needed.) */
const rom: WipDictionary = {
  metaTitle: "Chisto.mk · 20 maj 2026",
  metaDescription:
    "Platforma thaj ekologjia andre Makedonia. Raporto, dikhe mapa, zhuti khere. Startis 20 maj 2026.",
  launchDate: "Startis 20 maj 2026",
  badge: "Kam taj kerava",
  lead:
    "Kam taj kerava nevo thano, te raportes ekologisarja, te dikhes pe mapa, thaj te zhutes andre akcia andre Makedonia.",
  metaStrong: "Platforma thaj ekologjia",
  metaLine: "Puri platforma taj but. Isto misija, va zeleni Makedonia.",
  footer: "Makedonia",
  countdownDays: "Dive",
  countdownHours: "Ora",
  countdownMinutes: "Minuta",
  countdownSeconds: "Sekunda",
  countdownAria: "Vrema jek start",
  liveMessage: "Asom live. Dikh puri platforma.",
  languageSelectAria: "Chib",
  notifyTitle: "Zhuti",
  notifyDescription:
    "De e-mail, te zhutes kana startis platforma thaj kana si but lajme.",
  notifyPlaceholder: "tu@misal.com",
  notifySubmit: "De",
  notifySuccess: "Nais! Kam taj kerava kana zhuti but.",
  notifyErrorInvalid: "De lacho e-mail.",
  notifyErrorSave: "Nashti te ruvava. Prova but.",
  notifyAlreadySubscribed: "Kado e-mail hi but.",
  notifyLegalHint: "Vash Chisto.mk. Na e del vash aver.",
  notifyConsentLabel: "Kam te zhutav e-mail pa Chisto.mk pa kado.",
  notifyErrorConsent: "De o chek.",
  notifyTriggerLabel: "Zhuti misa",
  notifyTriggerLoadingLabel: "De dikhela…",
  notifySubscribedTriggerLabel: "Zhutido",
  notifyCloseLabel: "Bandal",
  notifyEmailLabel: "E-mail",
  notifySubmitPendingLabel: "De ruvava…",
  skipToContent: "Ja te but phuv",
  countdownLoadingStatus: "De dikhela",
};

const sr: WipDictionary = {
  metaTitle: "Chisto.mk · 20. мај 2026.",
  metaDescription:
    "Грађанска еколошка платформа за Македонију. Пријаве, мапа и акције чишћења. Почетак 20. маја 2026.",
  launchDate: "Почетак 20. маја 2026.",
  badge: "У припреми",
  lead:
    "Припремамо нови јавни простор за пријаву еколошких проблема, преглед на мапи и учешће у акцијама чишћења широм Македоније.",
  metaStrong: "Грађанска еколошка платформа",
  metaLine: "Цела платформа ускоро. Иста мисија, за зелену Македонију.",
  footer: "Македонија",
  countdownDays: "Дана",
  countdownHours: "Сати",
  countdownMinutes: "Минута",
  countdownSeconds: "Секунди",
  countdownAria: "Време до почетка",
  liveMessage: "Радимо уживо. Истражите целу платформу.",
  languageSelectAria: "Језик",
  notifyTitle: "Обавештења",
  notifyDescription:
    "Оставите е-пошту и јавићемо вам се за покретање платформе и за важне вести.",
  notifyPlaceholder: "ваша@епошта.рс",
  notifySubmit: "Пријави се",
  notifySuccess: "Хвала! Јавићемо вам се ускоро са важним новостима о платформи.",
  notifyErrorInvalid: "Унесите исправну е-пошту.",
  notifyErrorSave: "Чување није успело. Покушајте касније.",
  notifyAlreadySubscribed: "Ова е-пошта је већ пријављена.",
  notifyLegalHint: "Само за Chisto.mk. Не делимо адресу са другима.",
  notifyConsentLabel:
    "Слажем се да примам обавештења од Chisto.mk на ову е-пошту.",
  notifyErrorConsent: "Потребна је сагласност да бисте наставили.",
  notifyTriggerLabel: "Обавести ме",
  notifyTriggerLoadingLabel: "Учитава се…",
  notifySubscribedTriggerLabel: "Пријављени за обавештења",
  notifyCloseLabel: "Затвори",
  notifyEmailLabel: "Е-пошта",
  notifySubmitPendingLabel: "Чувам…",
  skipToContent: "Прескочи на главни садржај",
  countdownLoadingStatus: "Учитава се тајмер",
};

const dictionaries: Record<Locale, WipDictionary> = {
  mk,
  en,
  sq,
  rom,
  sr,
};

export function getDictionary(locale: Locale): WipDictionary {
  return dictionaries[locale];
}

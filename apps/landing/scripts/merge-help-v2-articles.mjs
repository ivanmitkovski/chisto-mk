/**
 * One-off merge: insert v2 help articles and hub keys into en/mk/sq messages.
 * Run: node scripts/merge-help-v2-articles.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

const DATA = {
  en: {
    hubPatch: {
      subtitle:
        "Guides for the Chisto.mk app and website: map, reporting, events, safety, offline use, account, and troubleshooting, aligned with what you see in the product.",
      featuredTitle: "Featured",
      featuredIntro: "Start here if you are new to the map or filing your first report.",
      catalogMetrics: "10 guides · wording matches the app and this site",
      featuredSlugs: ["getting-started", "exploring-the-map", "report-a-site"],
    },
    commonPatch: {
      copySectionLinkAria: "Copy link to section",
      sectionLinkCopied: "Link copied",
    },
    categoriesPatch: {
      map: { label: "Map and sites" },
    },
    articles: {
      "exploring-the-map": {
        cardTitle: "Exploring the map",
        cardSummary: "Pins, site pages, and how to read what is public in Macedonia.",
        title: "Exploring the map and site pages",
        lastUpdated: "15 April 2026",
        lastReviewed: "15 April 2026",
        sections: [
          {
            id: "what-the-map-shows",
            title: "What the map shows",
            blocks: [
              {
                type: "paragraph",
                text: "The map is a shared civic view of reported places in Macedonia. Each pin represents a site where people documented an environmental concern.",
              },
              {
                type: "bullets",
                title: "Quick orientation",
                items: [
                  "Zoom until street names and landmarks match what you see outside.",
                  "Tap a pin to open the site page with photos, descriptions, and history when available.",
                  "Newer activity may appear after moderation, so counts can change over time.",
                ],
              },
            ],
          },
          {
            id: "site-detail-basics",
            title: "Site detail basics",
            blocks: [
              {
                type: "paragraph",
                text: "A site page summarises what the community submitted. It is meant for transparency, not for assigning blame to individuals.",
              },
              {
                type: "bullets",
                title: "What you can rely on",
                items: [
                  "Photos and text come from contributors and moderators, not automated enforcement.",
                  "Timestamps help you understand recency when they are shown.",
                  "If something looks wrong, you can often add a new report rather than arguing in text.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "Do not treat map pins as legal proof on their own. Use official channels for regulated decisions.",
              },
            ],
          },
          {
            id: "moving-around-safely",
            title: "Moving around safely",
            blocks: [
              {
                type: "paragraph",
                text: "Use the map while stationary or as a passenger. Keep awareness of traffic and private property boundaries.",
              },
              {
                type: "bullets",
                title: "Good habits",
                items: [
                  "Prefer daylight for first visits to unfamiliar industrial edges.",
                  "If a path feels unsafe, step back and capture from a distance.",
                  "Respect no entry signs even when rubbish is visible beyond them.",
                ],
              },
            ],
          },
          {
            id: "when-to-file-a-report",
            title: "When to file a report",
            blocks: [
              {
                type: "paragraph",
                text: "Open a report when you can add fresh evidence or correct a pin. Duplicates without new facts slow moderation for everyone.",
              },
              {
                type: "bullets",
                title: "Before you start",
                items: [
                  "Gather photos and a clear description of what changed since the last visit.",
                  "Move the pin to the exact spot that needs attention.",
                  "Mention safety limits you observed so organisers can plan.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/report-a-site",
                label: "Report a pollution site",
              },
            ],
          },
        ],
      },
      "trust-safety-and-moderation": {
        cardTitle: "Trust, safety, and moderation",
        cardSummary: "How review works, respectful behaviour, and where binding policies live.",
        title: "Trust, safety, and moderation",
        lastUpdated: "15 April 2026",
        lastReviewed: "15 April 2026",
        sections: [
          {
            id: "why-moderation-exists",
            title: "Why moderation exists",
            blocks: [
              {
                type: "paragraph",
                text: "Chisto.mk publishes civic environmental signals. Moderation reduces spam, protects people from harassment, and keeps the map readable for partners and volunteers in Macedonia.",
              },
              {
                type: "bullets",
                title: "What reviewers look for",
                items: [
                  "Evidence that matches the location and time window you describe.",
                  "Respectful language without personal attacks.",
                  "Duplicates folded into the same site when that keeps the story clearer.",
                ],
              },
            ],
          },
          {
            id: "respectful-contributions",
            title: "Respectful contributions",
            blocks: [
              {
                type: "paragraph",
                text: "Assume good intent from neighbours and organisers. Focus on conditions you can photograph or describe factually.",
              },
              {
                type: "bullets",
                title: "Community norms",
                items: [
                  "No doxxing: avoid posting private addresses for people instead of sites.",
                  "No hate speech or coordinated brigading.",
                  "Do not upload imagery that sexualises minors or glorifies self harm.",
                ],
              },
              {
                type: "callout",
                variant: "tip",
                text: "If tempers rise, pause and capture facts only. Moderators prioritise safety over speed.",
              },
            ],
          },
          {
            id: "duplicates-and-corrections",
            title: "Duplicates and corrections",
            blocks: [
              {
                type: "paragraph",
                text: "Multiple reports about the same place can help show persistence, but identical copies add noise. Prefer updates with new angles or dates.",
              },
              {
                type: "bullets",
                title: "Practical guidance",
                items: [
                  "If a pin is slightly wrong, file a correction through the reporting flow when the product allows it.",
                  "If categories are wrong, choose the closest honest label and explain in text.",
                  "Expect status labels to lag briefly while humans review.",
                ],
              },
            ],
          },
          {
            id: "legal-detail-and-escalation",
            title: "Legal detail and escalation",
            blocks: [
              {
                type: "paragraph",
                text: "This article summarises behaviour expectations. Binding rules sit in the legal pages linked below.",
              },
              {
                type: "bullets",
                title: "Where to read more",
                items: [
                  "Privacy explains data categories and retention at a high level.",
                  "Terms explain acceptable use and enforcement levers.",
                  "The data page lists rights requests for account holders.",
                ],
              },
              {
                type: "internalLink",
                href: "/privacy",
                label: "Privacy policy",
              },
              {
                type: "internalLink",
                href: "/terms",
                label: "Terms of use",
              },
            ],
          },
        ],
      },
      "hosting-a-cleanup-event": {
        cardTitle: "Hosting a cleanup event",
        cardSummary: "Planning, sign ups, day of coordination, and wrap up after volunteers leave.",
        title: "Hosting a cleanup event",
        lastUpdated: "15 April 2026",
        lastReviewed: "15 April 2026",
        sections: [
          {
            id: "plan-before-you-publish",
            title: "Plan before you publish",
            blocks: [
              {
                type: "paragraph",
                text: "Organisers set the tone. Clear logistics reduce no shows and keep volunteers safer around roads, water edges, and weather shifts in Macedonia.",
              },
              {
                type: "bullets",
                title: "Checklist",
                items: [
                  "Pick a meeting pin, duration, difficulty, and any kit you will supply.",
                  "Confirm land access with owners or municipalities when required.",
                  "Publish contact expectations, for example whether phones stay on silent.",
                ],
              },
            ],
          },
          {
            id: "signups-and-messaging",
            title: "Sign ups and messaging",
            blocks: [
              {
                type: "paragraph",
                text: "Use notifications thoughtfully. Short updates beat long threads when plans change.",
              },
              {
                type: "bullets",
                title: "Operational tips",
                items: [
                  "Close registration early if capacity is limited.",
                  "Send a reminder the evening before with parking and toilet notes.",
                  "After cancellations, refresh headcounts so materials match reality.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/join-a-cleanup-event",
                label: "Join a cleanup event",
              },
            ],
          },
          {
            id: "day-of-safety",
            title: "Day of safety",
            blocks: [
              {
                type: "paragraph",
                text: "Brief everyone on hazards, buddy pairs, and what to do if someone feels unwell.",
              },
              {
                type: "bullets",
                title: "On site leadership",
                items: [
                  "Keep first aid basics and water visible.",
                  "Rotate heavy lifting roles and watch for heat stress.",
                  "Photograph results only where volunteers consent.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "For emergencies, use official emergency channels alongside any in app notes.",
              },
            ],
          },
          {
            id: "after-the-event",
            title: "After the event",
            blocks: [
              {
                type: "paragraph",
                text: "Close the loop with thank you notes, photo uploads if your flow supports them, and honest feedback for the next crew.",
              },
              {
                type: "bullets",
                title: "Wrap up",
                items: [
                  "Archive chat decisions so future hosts learn from your runbook.",
                  "Log issues that need municipal follow up separately from volunteer chatter.",
                  "Celebrate wins briefly so newcomers see momentum.",
                ],
              },
            ],
          },
        ],
      },
      "offline-and-slow-networks": {
        cardTitle: "Offline and slow networks",
        cardSummary: "What pending means, how uploads retry, and when to pause reporting.",
        title: "Offline and slow networks",
        lastUpdated: "15 April 2026",
        lastReviewed: "15 April 2026",
        sections: [
          {
            id: "how-the-app-uses-network",
            title: "How the app uses the network",
            blocks: [
              {
                type: "paragraph",
                text: "Maps, photos, and submissions sync when connectivity returns. Some screens cache tiles so you can browse lightly offline.",
              },
              {
                type: "bullets",
                title: "Expectations",
                items: [
                  "Account actions usually need a live session.",
                  "Draft fields may save locally until you submit.",
                  "Large photos take longer on 3G; queue them instead of forcing retries in a tunnel.",
                ],
              },
            ],
          },
          {
            id: "uploads-and-pending-states",
            title: "Uploads and pending states",
            blocks: [
              {
                type: "paragraph",
                text: "Pending means the device is still sending data or the server has not confirmed receipt. It is normal briefly after switching from Wi Fi to mobile data.",
              },
              {
                type: "bullets",
                title: "If you are stuck",
                items: [
                  "Open the report summary and look for retry or resume prompts.",
                  "Avoid duplicating the same submission while pending is spinning.",
                  "Capture smaller photos if uploads fail repeatedly.",
                ],
              },
            ],
          },
          {
            id: "airplane-mode-and-roaming",
            title: "Airplane mode and roaming",
            blocks: [
              {
                type: "paragraph",
                text: "International roaming can block background uploads. Toggle data for the app explicitly if your OS allows per app cellular control.",
              },
              {
                type: "bullets",
                title: "Travel tips",
                items: [
                  "Finish uploads before flights when possible.",
                  "Reconnect to Wi Fi before editing long descriptions.",
                  "If time zones shift, double check scheduled event reminders.",
                ],
              },
            ],
          },
          {
            id: "when-to-stop-and-escalate",
            title: "When to stop and escalate",
            blocks: [
              {
                type: "paragraph",
                text: "If the app crashes twice while uploading, pause and collect diagnostics such as OS version and app version before contacting support.",
              },
              {
                type: "bullets",
                title: "Escalation",
                items: [
                  "Try restarting the device once.",
                  "Reinstall only after backing up credentials.",
                  "Use the contact page on this site for persistent blockers.",
                ],
              },
              {
                type: "internalLink",
                href: "/contact",
                label: "Contact",
              },
            ],
          },
        ],
      },
    },
  },
  mk: {
    hubPatch: {
      subtitle:
        "Водичи за апликацијата и веб-страницата Chisto.mk: мапа, пријавување, настани, безбедност, офлајн, сметка и решавање проблеми, усогласени со она што го гледате во производот.",
      featuredTitle: "Истакнато",
      featuredIntro: "Почнете овде ако сте нови на мапата или ја поднесувате првата пријава.",
      catalogMetrics: "10 водичи · формулировката одговара на апликацијата и сајтот",
      featuredSlugs: ["getting-started", "exploring-the-map", "report-a-site"],
    },
    commonPatch: {
      copySectionLinkAria: "Копирај врска до секцијата",
      sectionLinkCopied: "Врската е копирана",
    },
    categoriesPatch: {
      map: { label: "Мапа и места" },
    },
    articles: {
      "exploring-the-map": {
        cardTitle: "Разгледување на мапата",
        cardSummary: "Пинови, страници за места и што е јавно видливо во Македонија.",
        title: "Мапа и страници за места",
        lastUpdated: "15 април 2026",
        lastReviewed: "15 април 2026",
        sections: [
          {
            id: "what-the-map-shows",
            title: "Што покажува мапата",
            blocks: [
              {
                type: "paragraph",
                text: "Мапата е заеднички граѓански преглед на пријавени места во Македонија. Секој пин е место каде луѓето документирале еколошка загриженост.",
              },
              {
                type: "bullets",
                title: "Брза ориентација",
                items: [
                  "Зумирајте додека имињата на улиците и обележјата одговараат на теренот.",
                  "Допрете пин за да ја отворите страницата со фотографии, опис и историја кога е достапна.",
                  "По модерација активноста може да се менува, па бројките се ажурираат со време.",
                ],
              },
            ],
          },
          {
            id: "site-detail-basics",
            title: "Основи на страницата за место",
            blocks: [
              {
                type: "paragraph",
                text: "Страницата ги сумира поднесоците од заедницата. Целта е транспарентност, не обвинување поединци.",
              },
              {
                type: "bullets",
                title: "На што можете да се потпрете",
                items: [
                  "Фотографиите и текстот доаѓаат од учесници и модератори, не од автоматско извршување.",
                  "Временските ознаки помагаат за свежина кога се прикажани.",
                  "Ако нешто изгледа погрешно, често е подобро нова пријава отколку долги расправии.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "Не третирајте ги пиновите како самостоен правен доказ. За регулаторни одлуки користете официјални канали.",
              },
            ],
          },
          {
            id: "moving-around-safely",
            title: "Безбедно движење",
            blocks: [
              {
                type: "paragraph",
                text: "Користете ја мапата стоејќи или како патник. Внимавајте на сообраќај и граници на приватна сопственост.",
              },
              {
                type: "bullets",
                title: "Добри навики",
                items: [
                  "Преферирајте дневна светлина за први посети на непознати индустриски работи.",
                  "Ако патот е небезбеден, одстапете и фотографирајте од далечина.",
                  "Почитувајте забрани за влез дури кога отпадот се гледа зад нив.",
                ],
              },
            ],
          },
          {
            id: "when-to-file-a-report",
            title: "Кога да поднесете пријава",
            blocks: [
              {
                type: "paragraph",
                text: "Отворете пријава кога имате свежи докази или корекција на пин. Дупликати без нови факти го успоруваат прегледот за сите.",
              },
              {
                type: "bullets",
                title: "Пред да почнете",
                items: [
                  "Соберете фотографии и јасен опис што се променило од последната посета.",
                  "Поместете го пинот на точното место што бара внимание.",
                  "Наведете ги безбедносните граници што ги забележавте за да можат организаторите да планираат.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/report-a-site",
                label: "Пријавете загадено место",
              },
            ],
          },
        ],
      },
      "trust-safety-and-moderation": {
        cardTitle: "Доверба, безбедност и модерација",
        cardSummary: "Како работи прегледот, почитува однесување и каде се обврзувачките политики.",
        title: "Доверба, безбедност и модерација",
        lastUpdated: "15 април 2026",
        lastReviewed: "15 април 2026",
        sections: [
          {
            id: "why-moderation-exists",
            title: "Зошто постои модерација",
            blocks: [
              {
                type: "paragraph",
                text: "Chisto.mk објавува граѓански еколошки сигнали. Модерацијата го намалува спамот, штити од вознемирување и ја одржува мапата читлива за партнери и волонтери во Македонија.",
              },
              {
                type: "bullets",
                title: "Што прегледувачите го бараат",
                items: [
                  "Докази што одговараат на локацијата и временската рамка што ја опишувате.",
                  "Почитува јазик без лични напади.",
                  "Дупликати споени на исто место кога тоа ја прави приказната појасна.",
                ],
              },
            ],
          },
          {
            id: "respectful-contributions",
            title: "Почитни придонеси",
            blocks: [
              {
                type: "paragraph",
                text: "Претпоставувајте добра намера кај соседите и организаторите. Фокусирајте се на услови што можете да ги фотографирате или фактички да ги опишете.",
              },
              {
                type: "bullets",
                title: "Норми на заедницата",
                items: [
                  "Без доксирање: избегнувајте објавување приватни адреси на луѓе наместо места.",
                  "Без говор на омраза или координирано напаѓање.",
                  "Не качувајте содржина што сексуализира малолетници или го слави самоповредувањето.",
                ],
              },
              {
                type: "callout",
                variant: "tip",
                text: "Ако напнатоста расте, паузирајте и фиксирајте само факти. Модераторите приоритет безбедност пред брзина.",
              },
            ],
          },
          {
            id: "duplicates-and-corrections",
            title: "Дупликати и корекции",
            blocks: [
              {
                type: "paragraph",
                text: "Повеќе пријави за исто место можат да покажат истрајност, но идентични копии додаваат шум. Преферирајте ажурирања со нов агол или датум.",
              },
              {
                type: "bullets",
                title: "Практични совети",
                items: [
                  "Ако пинот е малку погрешен, поднесете корекција преку текот за пријава кога производот дозволува.",
                  "Ако категориите се погрешни, изберете најблиска чесна етикета и објаснете во текст.",
                  "Очекувајте етикети за статус да доцнат додека луѓе прегледуваат.",
                ],
              },
            ],
          },
          {
            id: "legal-detail-and-escalation",
            title: "Правни детали и ескалација",
            blocks: [
              {
                type: "paragraph",
                text: "Оваа статија ги сумира очекувањата за однесување. Обврзувачките правила се на поврзаните правни страници.",
              },
              {
                type: "bullets",
                title: "Каде да читате повеќе",
                items: [
                  "Приватноста објаснува категории на податоци и задржување на високо ниво.",
                  "Условите објаснуваат дозволена употреба и механизми за спроведување.",
                  "Страницата за податоци ги наведува барањата за права за сметките.",
                ],
              },
              {
                type: "internalLink",
                href: "/privacy",
                label: "Политика за приватност",
              },
              {
                type: "internalLink",
                href: "/terms",
                label: "Услови за користење",
              },
            ],
          },
        ],
      },
      "hosting-a-cleanup-event": {
        cardTitle: "Организирање акција за чистење",
        cardSummary: "Планирање, пријави, координација во денот и завршување по заминување на волонтерите.",
        title: "Организирање акција за чистење",
        lastUpdated: "15 април 2026",
        lastReviewed: "15 април 2026",
        sections: [
          {
            id: "plan-before-you-publish",
            title: "План пред објавување",
            blocks: [
              {
                type: "paragraph",
                text: "Организаторите го поставуваат тонот. Јасна логистика ги намалува нејавувањата и ги прави волонтерите побезбедни крај патишта, вода и временски промени во Македонија.",
              },
              {
                type: "bullets",
                title: "Листа за проверка",
                items: [
                  "Изберете точка на собирање, времетраење, тежина и опрема што ја обезбедувате.",
                  "Потврдете пристап до земјиште со сопственици или општини каде што е потребно.",
                  "Објавете очекувања за контакт, на пример дали телефоните остануваат на тивки режими.",
                ],
              },
            ],
          },
          {
            id: "signups-and-messaging",
            title: "Пријави и пораки",
            blocks: [
              {
                type: "paragraph",
                text: "Користете известувања разумно. Кратки ажурирања се подобри од долги нити кога плановите се менуваат.",
              },
              {
                type: "bullets",
                title: "Оперативни совети",
                items: [
                  "Затворете ја регистрацијата навреме ако капацитетот е ограничен.",
                  "Испратете потсетник вечер пред со паркирање и тоалети.",
                  "По откажувања освежете ги броевите за да одговараат материјалите на реалноста.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/join-a-cleanup-event",
                label: "Придружете се на акција",
              },
            ],
          },
          {
            id: "day-of-safety",
            title: "Безбедност во денот",
            blocks: [
              {
                type: "paragraph",
                text: "Кратко упатете за опасности, парови задолжени и што да се прави ако некому му е лошо.",
              },
              {
                type: "bullets",
                title: "Водење на терен",
                items: [
                  "Држете прва помош и вода на видно место.",
                  "Ротирајте тешко кревање и следете топлотен стрес.",
                  "Фотографирајте резултати само кога волонтерите се согласуваат.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "За итни случаи користете официјални итни канали покрај белешките во апликацијата.",
              },
            ],
          },
          {
            id: "after-the-event",
            title: "По настанот",
            blocks: [
              {
                type: "paragraph",
                text: "Затворете ја јамката со благодарност, качување фотографии ако текот го поддржува и искрена повратна информација за следниот тим.",
              },
              {
                type: "bullets",
                title: "Завршување",
                items: [
                  "Архивирајте одлуки од разговори за да учат идни домаќини.",
                  "Евидентирајте прашања за општинско следење одделно од волонтерски разговор.",
                  "Кратко прославете успеси за да новодојденците видат движење напред.",
                ],
              },
            ],
          },
        ],
      },
      "offline-and-slow-networks": {
        cardTitle: "Офлајн и бавни мрежи",
        cardSummary: "Што значи „во чекање“, како се обидуваат качувања и кога да паузирате со пријавување.",
        title: "Офлајн и бавни мрежи",
        lastUpdated: "15 април 2026",
        lastReviewed: "15 април 2026",
        sections: [
          {
            id: "how-the-app-uses-network",
            title: "Како апликацијата ја користи мрежата",
            blocks: [
              {
                type: "paragraph",
                text: "Мапи, фотографии и поднесоци се синхронизираат кога конекцијата се враќа. Некои екрани кешираат плочи за лесно офлајн разгледување.",
              },
              {
                type: "bullets",
                title: "Очекувања",
                items: [
                  "Дејствија на сметката обично бараат активна сесија.",
                  "Полињата во нацрт може локално да се зачуваат додека не поднесете.",
                  "Големите фотографии траат подолго на 3G; редот е подобар од насилни повторни обиди во тунел.",
                ],
              },
            ],
          },
          {
            id: "uploads-and-pending-states",
            title: "Качувања и статус „во чекање“",
            blocks: [
              {
                type: "paragraph",
                text: "Во чекање значи уредот сè уште испраќа податоци или серверот не потврдил прием. Кратко задоцнување е нормално по префрлање од Wi Fi на мобилни податоци.",
              },
              {
                type: "bullets",
                title: "Ако сте заглавени",
                items: [
                  "Отворете го прегледот на пријавата и побарајте копчиња за повторен обид или продолжување.",
                  "Избегнувајте дуплирање на ист поднесок додека се врти статусот.",
                  "Користете помали фотографии ако качувањата постојано паѓаат.",
                ],
              },
            ],
          },
          {
            id: "airplane-mode-and-roaming",
            title: "Авионски режим и роаминг",
            blocks: [
              {
                type: "paragraph",
                text: "Меѓународниот роаминг може да ги блокира позадинските качувања. Явно вклучете податоци за апликацијата ако ОС дозволува по апликација.",
              },
              {
                type: "bullets",
                title: "Совети за патување",
                items: [
                  "Завршете ги качувањата пред летови кога е можно.",
                  "Повторно се поврзете на Wi Fi пред долги уредувања на опис.",
                  "Ако се менуваат временски зони, проверете ги потсетниците за настани.",
                ],
              },
            ],
          },
          {
            id: "when-to-stop-and-escalate",
            title: "Кога да запрете и да ескалирате",
            blocks: [
              {
                type: "paragraph",
                text: "Ако апликацијата се урна двапати при качување, паузирајте и соберете дијагностика како верзија на апликација и ОС пред контакт со поддршка.",
              },
              {
                type: "bullets",
                title: "Ескалација",
                items: [
                  "Обидете се еднаш со рестарт на уредот.",
                  "Преинсталирајте само откако ќе ги заштитите креденцијалите.",
                  "Користете ја контакт страницата на сајтот за трајни блокади.",
                ],
              },
              {
                type: "internalLink",
                href: "/contact",
                label: "Контакт",
              },
            ],
          },
        ],
      },
    },
  },
  sq: {
    hubPatch: {
      subtitle:
        "Udhëzues për aplikacionin dhe sajtin Chisto.mk: hartë, raportim, ngjarje, siguri, oflajn, llogari dhe zgjidhje problemesh, në përputhje me atë që shihni në produkt.",
      featuredTitle: "Të theksuara",
      featuredIntro: "Filloni këtu nëse jeni të rinj në hartë ose po parashtroni raportin e parë.",
      catalogMetrics: "10 udhëzues · formulimi përputhet me aplikacionin dhe sajtin",
      featuredSlugs: ["getting-started", "exploring-the-map", "report-a-site"],
    },
    commonPatch: {
      copySectionLinkAria: "Kopjo lidhjen te seksioni",
      sectionLinkCopied: "Lidhja u kopjua",
    },
    categoriesPatch: {
      map: { label: "Harta dhe vendet" },
    },
    articles: {
      "exploring-the-map": {
        cardTitle: "Eksplorimi i hartës",
        cardSummary: "Pina, faqet e vendeve dhe çfarë është publike në Maqedoni.",
        title: "Harta dhe faqet e vendeve",
        lastUpdated: "15 prill 2026",
        lastReviewed: "15 prill 2026",
        sections: [
          {
            id: "what-the-map-shows",
            title: "Çfarë tregon harta",
            blocks: [
              {
                type: "paragraph",
                text: "Harta është një pamje qytetare e vendeve të raportuara në Maqedoni. Çdo pin përfaqëson një vend ku njerëzit dokumentuan një shqetësim mjedisor.",
              },
              {
                type: "bullets",
                title: "Orientim i shpejtë",
                items: [
                  "Zmadhoni derisa emrat e rrugëve dhe pikat e referencës përputhen me atë që shihni jashtë.",
                  "Prekni një pin për të hapur faqen me foto, përshkrim dhe histori kur është e disponueshme.",
                  "Pas moderimit aktiviteti mund të ndryshojë, ndaj numrat përditësohen me kohën.",
                ],
              },
            ],
          },
          {
            id: "site-detail-basics",
            title: "Bazat e faqes së vendit",
            blocks: [
              {
                type: "paragraph",
                text: "Faqja përmbledh atë që ka parashtruar komuniteti. Qëllimi është transparencë, jo fajësim i individëve.",
              },
              {
                type: "bullets",
                title: "Mbi çfarë mund të mbështeteni",
                items: [
                  "Fotot dhe teksti vijnë nga kontribues dhe moderatorë, jo nga zbatimi automatik.",
                  "Vulat kohore ndihmojnë për freskinë kur shfaqen.",
                  "Nëse diçka duket gabim, shpesh një raport i ri është më mirë se debate të gjata.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "Mos i trajtoni pinat si provë ligjore vetë. Për vendime të rregulluara përdorni kanale zyrtare.",
              },
            ],
          },
          {
            id: "moving-around-safely",
            title: "Lëvizje e sigurt",
            blocks: [
              {
                type: "paragraph",
                text: "Përdorni hartën në këmbë ose si pasagjer. Ruani vëmendjen për trafikun dhe kufijtë e pronës private.",
              },
              {
                type: "bullets",
                title: "Zakonet e mira",
                items: [
                  "Preferoni dritën e ditës për vizitat e para në skaje industriale të panjohura.",
                  "Nëse rruga duket e pasigurt, hapni distancë dhe fotografoni nga larg.",
                  "Respektoni sinjalet e ndalimit edhe kur mbeturinat duken përtej tyre.",
                ],
              },
            ],
          },
          {
            id: "when-to-file-a-report",
            title: "Kur të parashtroni një raport",
            blocks: [
              {
                type: "paragraph",
                text: "Hapni një raport kur keni prova të reja ose korrigjim të pin-it. Dublikatet pa fakte të reja e ngadalësojnë moderimin për të gjithë.",
              },
              {
                type: "bullets",
                title: "Para se të filloni",
                items: [
                  "Mblidhni foto dhe një përshkrim të qartë se çfarë ndryshoi që nga vizita e fundit.",
                  "Zhvendosni pinin në pikën e saktë që kërkon vëmendje.",
                  "Përmendni kufijtë e sigurisë që vëzhguat që organizatorët të planifikojnë.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/report-a-site",
                label: "Raportoni një vend të ndotur",
              },
            ],
          },
        ],
      },
      "trust-safety-and-moderation": {
        cardTitle: "Besim, siguri dhe moderim",
        cardSummary: "Si funksionon shqyrtimi, sjellja respektuese dhe ku janë politikat zyrtare.",
        title: "Besim, siguri dhe moderim",
        lastUpdated: "15 prill 2026",
        lastReviewed: "15 prill 2026",
        sections: [
          {
            id: "why-moderation-exists",
            title: "Pse ekziston moderimi",
            blocks: [
              {
                type: "paragraph",
                text: "Chisto.mk publikon sinjale qytetare mjedisore. Moderimi ul spam-in, mbron nga ngacmimi dhe e mban hartën të lexueshme për partnerë dhe vullnetarë në Maqedoni.",
              },
              {
                type: "bullets",
                title: "Çfarë kërkojnë rishikuesit",
                items: [
                  "Provë që përputhet me vendndodhjen dhe dritaren kohore që përshkruani.",
                  "Gjuhë respektuese pa sulme personale.",
                  "Dublikatet bashkohen në të njëjtin vend kur kjo e bën historinë më të qartë.",
                ],
              },
            ],
          },
          {
            id: "respectful-contributions",
            title: "Kontribute respektuese",
            blocks: [
              {
                type: "paragraph",
                text: "Supozoni qëllim të mirë te fqinjët dhe organizatorët. Fokusohuni në kushte që mund t'i fotografoni ose përshkruani faktikisht.",
              },
              {
                type: "bullets",
                title: "Normat e komunitetit",
                items: [
                  "Pa doxxing: shmangni postimin e adresave private të njerëzve në vend të vendeve.",
                  "Pa gjuhë urrejtjeje ose sulme të koordinuara.",
                  "Mos ngarkoni përmbajtje që seksualizon fëmijët ose lavdëron vetëdëmtimin.",
                ],
              },
              {
                type: "callout",
                variant: "tip",
                text: "Nëse tensioni rritet, pushoni dhe fiksoni vetëm fakte. Moderatorët vënë sigurinë para shpejtësisë.",
              },
            ],
          },
          {
            id: "duplicates-and-corrections",
            title: "Dublikate dhe korrigjime",
            blocks: [
              {
                type: "paragraph",
                text: "Disa raporte për të njëjtin vend mund të tregojnë qëndresë, por kopje identike shtojnë zhurmë. Preferoni përditësime me kënd ose datë të re.",
              },
              {
                type: "bullets",
                title: "Udhëzime praktike",
                items: [
                  "Nëse pin-i është pak i gabuar, parashtroni korrigjim përmes rrjedhës së raportimit kur produkti lejon.",
                  "Nëse kategoritë janë të gabuara, zgjidhni etiketën më të ndershme dhe shpjegoni në tekst.",
                  "Pritni që etiketat e statusit të vonohen pak ndërsa njerëzit rishikojnë.",
                ],
              },
            ],
          },
          {
            id: "legal-detail-and-escalation",
            title: "Detaje ligjore dhe eskalim",
            blocks: [
              {
                type: "paragraph",
                text: "Ky artikull përmbledh pritshmëritë e sjelljes. Rregullat zyrtare janë në faqet e lidhura më poshtë.",
              },
              {
                type: "bullets",
                title: "Ku të lexoni më shumë",
                items: [
                  "Privatësia shpjegon kategoritë e të dhënave dhe mbajtjen në nivel të lartë.",
                  "Kushtet shpjegojnë përdorimin e lejuar dhe mekanizmat e zbatimit.",
                  "Faqja e të dhënave liston kërkesat e të drejtave për mbajtësit e llogarive.",
                ],
              },
              {
                type: "internalLink",
                href: "/privacy",
                label: "Politika e privatësisë",
              },
              {
                type: "internalLink",
                href: "/terms",
                label: "Kushtet e përdorimit",
              },
            ],
          },
        ],
      },
      "hosting-a-cleanup-event": {
        cardTitle: "Organizimi i një aksioni pastrimi",
        cardSummary: "Planifikimi, regjistrimet, koordinimi në ditën e ngjarjes dhe mbyllja pasi vullnetarët largohen.",
        title: "Organizimi i një aksioni pastrimi",
        lastUpdated: "15 prill 2026",
        lastReviewed: "15 prill 2026",
        sections: [
          {
            id: "plan-before-you-publish",
            title: "Planifikoni para publikimit",
            blocks: [
              {
                type: "paragraph",
                text: "Organizatorët vendosin tonin. Logjistikë e qartë ul mungesat dhe i bën vullnetarët më të sigurt pranë rrugëve, ujit dhe ndryshimeve të motit në Maqedoni.",
              },
              {
                type: "bullets",
                title: "Lista kontrolluese",
                items: [
                  "Zgjidhni një pin takimi, kohëzgjatje, vështirësi dhe çfarë pajisjesh ofroni.",
                  "Konfirmoni aksesin në tokë me pronarë ose bashki kur duhet.",
                  "Publikoni pritshmëritë e kontaktit, për shembull nëse telefonat mbeten në heshtje.",
                ],
              },
            ],
          },
          {
            id: "signups-and-messaging",
            title: "Regjistrime dhe mesazhe",
            blocks: [
              {
                type: "paragraph",
                text: "Përdorni njoftimet me mend. Përditësime të shkurtra janë më të mira se fije të gjata kur planet ndryshojnë.",
              },
              {
                type: "bullets",
                title: "Këshilla operative",
                items: [
                  "Mbyllni regjistrimin herët nëse kapaciteti është i kufizuar.",
                  "Dërgoni një kujtues mbrëmjen para me parkim dhe tualet.",
                  "Pas anulimeve rifreskoni numrat që materialet të përputhen me realitetin.",
                ],
              },
              {
                type: "internalLink",
                href: "/help/join-a-cleanup-event",
                label: "Bashkohuni në një aksion pastrimi",
              },
            ],
          },
          {
            id: "day-of-safety",
            title: "Siguria në ditën e ngjarjes",
            blocks: [
              {
                type: "paragraph",
                text: "Informoni shkurt për rreziqet, çiftet e mbështetjes dhe çfarë të bëni nëse dikujt i përkeqësohet gjendja.",
              },
              {
                type: "bullets",
                title: "Udhëheqje në vend",
                items: [
                  "Mbajeni ndihmën e parë dhe ujin në dukje.",
                  "Rrotulloni rolet e ngritjes së rëndë dhe vëzhgoni nxehtësinë.",
                  "Fotografoni rezultatet vetëm kur vullnetarët bien dakord.",
                ],
              },
              {
                type: "callout",
                variant: "note",
                text: "Për emergjenca përdorni kanale zyrtare emergjence përveç shënimeve në aplikacion.",
              },
            ],
          },
          {
            id: "after-the-event",
            title: "Pas ngjarjes",
            blocks: [
              {
                type: "paragraph",
                text: "Mbyllni ciklin me falënderim, ngarkim fotografish nëse rrjedha e mbështet dhe komente të ndershme për ekipin tjetër.",
              },
              {
                type: "bullets",
                title: "Përfundimi",
                items: [
                  "Arkivoni vendimet e bisedave që hostët e ardhshëm të mësojnë nga dosja.",
                  "Regjistroni çështjet që kërkin ndjekje bashkiake veç nga biseda vullnetare.",
                  "Festoni shkurt fitimet që të rinjtë të shohin lëvizje përpara.",
                ],
              },
            ],
          },
        ],
      },
      "offline-and-slow-networks": {
        cardTitle: "Oflajn dhe rrjete të ngadalta",
        cardSummary: "Çfarë do të thotë në pritje, si provohen përsëri ngarkimet dhe kur të ndaloni raportimin.",
        title: "Oflajn dhe rrjete të ngadalta",
        lastUpdated: "15 prill 2026",
        lastReviewed: "15 prill 2026",
        sections: [
          {
            id: "how-the-app-uses-network",
            title: "Si aplikacioni përdor rrjetin",
            blocks: [
              {
                type: "paragraph",
                text: "Hartat, fotot dhe parashtrimet sinkronizohen kur lidhja kthehet. Disa ekrane fshehin pllaka për shfletim të lehtë oflajn.",
              },
              {
                type: "bullets",
                title: "Pritshmëritë",
                items: [
                  "Veprimet e llogarisë zakonisht kërkojnë sesion të drejtpërdrejtë.",
                  "Fushat e skicës mund të ruhen lokalisht derisa të parashtroni.",
                  "Fotot e mëdha zgjasin më shumë në 3G; radhitja është më mirë se përpjekjet e detyruara në tunel.",
                ],
              },
            ],
          },
          {
            id: "uploads-and-pending-states",
            title: "Ngarkime dhe gjendje në pritje",
            blocks: [
              {
                type: "paragraph",
                text: "Në pritje do të thotë pajisja ende po dërgon të dhëna ose serveri nuk ka konfirmuar marrjen. Një vonesë e shkurtër është normale pas kalimit nga Wi Fi në celular.",
              },
              {
                type: "bullets",
                title: "Nëse jeni ngulur",
                items: [
                  "Hapni përmbledhjen e raportit dhe kërkoni butona për riprovim ose vazhdim.",
                  "Shmangni dublikimin e të njëjtit parashtrim ndërsa statusi po rrotullohet.",
                  "Përdorni foto më të vogla nëse ngarkimet dështojnë vazhdimisht.",
                ],
              },
            ],
          },
          {
            id: "airplane-mode-and-roaming",
            title: "Modaliteti avion dhe roamingu",
            blocks: [
              {
                type: "paragraph",
                text: "Roamingu ndërkombëtar mund të bllokojë ngarkimet në sfond. Aktivizoni qartë të dhënat për aplikacionin nëse OS lejon kontroll për aplikacion.",
              },
              {
                type: "bullets",
                title: "Këshilla udhëtimi",
                items: [
                  "Përfundoni ngarkimet para fluturimeve kur është e mundur.",
                  "Rilidhuni me Wi Fi para redaktimit të gjatë të përshkrimeve.",
                  "Nëse ndryshojnë zonat kohore, kontrolloni kujtuesit e ngjarjeve.",
                ],
              },
            ],
          },
          {
            id: "when-to-stop-and-escalate",
            title: "Kur të ndaloni dhe të eskaloni",
            blocks: [
              {
                type: "paragraph",
                text: "Nëse aplikacioni bie dy herë gjatë ngarkimit, ndaloni dhe mblidhni diagnostikë si versioni i aplikacionit dhe OS para kontaktit me mbështetje.",
              },
              {
                type: "bullets",
                title: "Eskalimi",
                items: [
                  "Provoni një herë rinisjen e pajisjes.",
                  "Rinstaloni vetëm pasi të keni rezervuar kredencialet.",
                  "Përdorni faqen e kontaktit të sajtit për bllokime të qëndrueshme.",
                ],
              },
              {
                type: "internalLink",
                href: "/contact",
                label: "Kontakt",
              },
            ],
          },
        ],
      },
    },
  },
};

function mergeLocale(filename, localeKey) {
  const p = path.join(root, "messages", filename);
  const raw = fs.readFileSync(p, "utf8");
  const j = JSON.parse(raw);
  const pack = DATA[localeKey];
  Object.assign(j.helpCentre.hub, pack.hubPatch);
  Object.assign(j.helpCentre.common, pack.commonPatch);
  Object.assign(j.helpCentre.categories, pack.categoriesPatch);
  for (const [slug, article] of Object.entries(pack.articles)) {
    j.helpCentre.articles[slug] = article;
  }
  fs.writeFileSync(p, `${JSON.stringify(j, null, 2)}\n`);
}

mergeLocale("en.json", "en");
mergeLocale("mk.json", "mk");
mergeLocale("sq.json", "sq");
console.log("merged help v2 articles + hub keys into en, mk, sq");

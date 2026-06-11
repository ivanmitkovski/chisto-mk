# Macedonian environmental & cleanup terminology (MK)

Standard copy for nationwide UI, organizer education, and volunteer flows. Prefer terms used by municipalities, NGOs, and public institutions.

## Waste bags & equipment

| Concept | Use | Avoid |
|--------|-----|-------|
| Gear volunteers should **bring** (event creation gear picker) | **Вреќи за отпад** (plural) | Џувалја, торби |
| **Collected** waste bags counted during/after cleanup | **Ќеси (за отпад)** | торби, ќесиња (diminutive), ќесии, џувалја |
| Singular bag in instructions | **ќеса за отпад** | ќесија |

English key `eventsGearTrashBags` → MK **Вреќи за отпад**.  
Impact counters, live pulse, completion UI, organizer quiz q16 → **ќеси за отпад**.

## Waste & cleanup (general)

| Concept | Use | Avoid in formal UI |
|--------|-----|---------------------|
| Litter / refuse (noun) | **отпад** | ѓубре (colloquial) |
| Piles of dumped waste | **купови отпад** | купишта ѓубре |
| Removing waste after collection | **отстранување** | одлагање in short titles (confusable with **одложување** = postpone) |
| Postponing an event | **одложување / одложете** | одлагање |

## Equipment lists (reference)

Typical volunteer gear labels in-app:

- Ракавици
- **Вреќи за отпад**
- Гребла и лопати (not „грабли" — Serbian/Croatian)
- Рачна количка (plain „количка" reads as stroller/shopping cart)
- Гумени чизми (not „чизми за вода")
- Рефлектирачки елек
- Прибор за прва помош (not „апчиња" — that means pills)
- Крема за сончање и вода

## Audit log (2026-06-09)

- `eventsGearTrashBags`: Џувалја за отпад → **Вреќи за отпад**
- `eventsImpactReceiptShareSummary`, `eventsOrganizerCompletionStepImpactBody`, `eventsScaleSmallDescription`: торби → **ќеси**
- `eventsCategoryGeneralCleanupDescription`: ѓубре → **отпад**
- `reportCategoryIllegalLandfillDescription`: купишта ѓубре → **купови отпад**
- Organizer quiz (`mk.json`): q16 **ќесии** → **ќеси за отпад** + verb fix; q5/q12 **ќеси за отпад**; q5_b **отстранување**; q6 **постоен темпo**
- Mobile quiz UI: failed-body grammar; formal **Обидете се** / **Поднесете одговори**
- Prior pass: organizer toolkit slide 5, snooze title, quiz q12, ќесиња/ќесија → вreќi/ќесa

## Audit log (2026-06-10)

- `organizerToolkitPage6Body` + quiz q6_b: постојан/постоен темпо → **постојано темпо** (neuter agreement)
- `organizerQuizPassedTitle`: Сертифициран сте → **Сертифицирани сте** (gender-neutral formal)
- `eventsGearRakes`: Грабли и лопати → **Гребла и лопати**
- `eventsGearWheelbarrow`: Количка → **Рачна количка**
- `eventsGearWaterBoots`: Чизми за вода → **Гумени чизми**
- `eventsGearFirstAid`: Апчиња за прва помош → **Прибор за прва помош** (апчиња = pills)
- `eventsGearSunscreen`: Сончев крем и вода → **Крема за сончање и вода**
- Gear picker sheet: removed duplicated multi-select instruction; subtitle now «Изберете сè …»

When adding new MK copy, grep for: `Џувал`, `торби`, `ѓубre`, `одлагање`, `ќесиња`, `ќесии`.

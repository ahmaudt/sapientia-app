# Matins, Evensong and Compline — Notices Only

Created: 2026-09-04
Author: ahmaud@gmail.com
Agent: Claude Code
Category: Feature
Status: Final
Research: Standard

## Problem Statement

Sapientia announces the three Little Hours — Terce, Sext and None — and carries their full text
for praying in the app. The three offices that actually anchor an Ordinariate layman's day —
Matins, Evensong and Compline — get nothing at all. The app is silent at 8:45 in the morning and
silent again at half past five, which are the two moments its user is most likely to want a nudge.

That silence was a deliberate decision, recorded on screen 29 as *"Quiet. Matins and Evensong
belong to the parish."* The decision was right about where the office belongs and wrong about what
follows from it. Belonging to the parish is a reason not to ship the *text* — it is a reason **to**
ship the *call*. A layman who prays Evensong at the parish, or at home from a physical copy of
*Divine Worship: Daily Office*, still needs to be told it is half past five.

So: three more notices, and nothing else. No reader, no bundled psalter, no lectionary. Where
Universalis and iBreviary compete on holding the complete office, Sapientia deliberately holds none
of it for these three. The notice points at the book; the book is not in the app. That inversion is
the feature.

## Core User Flows

### Flow 1: Turning on Evensong

1. User opens **Settings → Reminders** (screen 29), or taps **Remind** from The Hours.
2. Below the existing **The Little Hours** section they find a second section listing
   **Matins**, **Evensong** and **Compline**, each with a time and a toggle — the same row
   shape as the Little Hours above.
3. User taps Evensong's time, picks 17:30 on the wheel, and confirms.
4. The preference is written and pending notices are rebuilt immediately; no relaunch is needed.

### Flow 2: The notice arrives

1. At the set time, iOS delivers a notice naming the office and the day —
   e.g. **"Evensong"** / *"Michaelmas."*
2. Tapping it opens Sapientia to its normal home screen. **It does not open an office reader,
   because there is none.** The user prays from the parish's book or their own.
3. Nothing repeats and nothing chases. One notice per office per day, and it expires with the day.

### Flow 3: Sunday

1. Sundays for these three are **on by default** — Sunday is exactly when the parish call matters.
2. A separate **On Sundays** control in Conduct governs these three offices only. The Little Hours
   keep their existing Sunday preference, unchanged and still off by default.

### Flow 4: Notices are refused at the system level

1. User has previously denied notification permission for Sapientia.
2. The Reminders screen already shows *"Notices are turned off for Sapientia in iOS Settings"* with
   an **Open** affordance. This continues to cover the new section — the warning is about the app,
   not about a section of it, and must not be duplicated per section.

## Scope

### In Scope

- **Three new notice-only offices**: Matins, Evensong, Compline. Each has an on/off toggle and an
  editable time, stored in the same app-group preference suite as the Little Hours.
- **Defaults grounded in the source the app already follows**: Matins **08:45**, Evensong **17:30**,
  Compline **21:00**. The first two are the published times of the Ordinariate of the Chair of Saint
  Peter community at `prayer.covert.org`, from which the existing office dataset was generated;
  Compline has no canonical clock hour in any source and 21:00 is a chosen convention.
- **A second section on the Reminders screen** (screen 29), beneath The Little Hours, reusing the
  existing row treatment, time picker and toggle style so the screen reads as one screen.
- **Its own "On Sundays" toggle in Conduct, defaulting on**, scoped to these three offices.
- **Notice content**: the office name as title, and the day's liturgical designation as body, drawn
  from `OrdinariateCalendar` — the same source the feast notices already use. No new liturgical
  text is bundled, transcribed, or fetched.
- **Titles are the bare office name** — "Matins", "Evensong", "Compline" — in both the notice and
  the settings row. The Little Hours' two-part `displayTitle` ("Midmorning — Terce") exists because
  those offices carry both an English name and a Latin one and the screens show both; these three
  have a single name apiece, and "Morning Prayer — Matins" would be one name said twice.
- **Naming follows the North American Edition**, which is the edition the app already tracks:
  **Matins** (one *t*), **Evensong**, **Compline**.
- **The pending-notification budget stays within iOS's 64-request ceiling**, with headroom left for
  session timers. This is a hard acceptance requirement, not a nicety — see Technical Context.
- **Session lifecycle must never delete these notices**, matching the promise the Reminders screen
  already makes for the Little Hours.
- **The notice preview card on screen 29 must keep depicting a real notice** that the scheduler
  could actually produce, rather than drifting into a mock-up of something the app never sends.

### Explicitly Out of Scope

- **The text of Matins, Evensong and Compline** — no reader, no psalter, no canticles, no bundled
  dataset. This is the premise of the request, not an omission: the user prays at the parish or from
  a physical *Divine Worship: Daily Office*.
- **Lectionary references in the notice** (today's psalms or lessons for Matins) — the Little Hours
  notices can name their psalms only because those psalms are fixed and bundled. Matching that here
  would require shipping the Ordinariate Lectionary, which is exactly the data this feature refuses
  to hold.
- **Kept-hours tracking for these three** — no "prayed" record, no entry in the week grid, no rows on
  The Hours (screen 25). The grid stays an honest count of offices actually prayed *in the app*, and
  its denominator is unchanged. Nothing the app cannot observe gets counted.
- **Notification actions** ("Prayed", "Snooze", "Remind me in 10") — the existing notices carry none,
  and adding them here would make the new offices behave unlike the old ones on the same screen.
- **A widget or Live Activity for the next office** — already recorded as a deferred idea in the
  Little Hours plan (`docs/plans/2026-08-27-little-hours-daily-office.md`); it stays deferred.
- **The Mac target.** iOS only, matching the Little Hours release.
- **Any change to blocking, profiles, sessions or the shield.** This feature is additive.

## Technical Context

Existing structures this feature meets. Everything below is a statement about code that is already
in the repository or a constraint that already binds it — the implementation approach is `/spec`'s
to determine.

- **Scheduling.** `Sapientia/Liturgy/OfficeNotificationScheduler.swift` schedules the Little Hours
  as a rolling 10-day window of `UNCalendarNotificationTrigger` requests prefixed `office-`, rebuilt
  on every foreground. `FeastNotificationScheduler.swift` does the same for feasts over 14 days at
  06:00, and owns the `UserNotificationCentering` protocol seam that makes both testable.
- **Preferences.** `LittleHoursSettings.swift` stores per-hour enable flags and times in the
  `group.com.artempleton.sapientia` suite, times as minutes-from-midnight rather than `Date`, and
  reads through `object(forKey:)` so an absent key is distinguishable from a real zero.
- **Liturgical data for the body already exists.** `OrdinariateCalendar.day(for:)` returns
  `dayName`, `commemorationText` and `collect`; `FeastNotificationScheduler` already composes a
  notice from exactly these fields. No new data source is needed for the chosen body content.
- **The notification budget is the binding constraint.** iOS caps pending local notifications at
  **64 per app** and silently discards the excess. Current worst-case consumption is **44** — up to
  30 Little Hours (3 offices × 10 days) plus 14 feast notices — before `TimersUtil`'s session
  notices. Three more offices on the existing 10-day window would add 30, for 74. Something must
  give, and the acceptance requirement above is that the total stays under 64 with room for timers.
- **The chosen body content constrains the cheap escape route.** A `UNCalendarNotificationTrigger`
  with `repeats: true` costs one pending slot per office regardless of horizon, but can only carry
  fixed text. Naming the day's liturgy makes the body vary daily, which is the case that requires a
  rolling reschedule. This trade-off was accepted deliberately (see Key Decisions).
- **Session cleanup.** `TimersUtil.preservedPrefixes` lists the identifier prefixes that survive a
  session starting or stopping. Anything not listed there is wiped when a rule begins.
- **Screen 29.** `Sapientia/Views/PrayerRemindersView.swift` renders the screen;
  `Sapientia/Components/Office/PrayerRemindersModel.swift` holds its copy and row model, and
  `RemindersEditor` in that file is the single mutation path — every edit reschedules, so none can
  forget to.
- **Existing test coverage to extend rather than duplicate**: `sapientiaTests/OfficeNotificationTests.swift`,
  `PrayerRemindersTests.swift`, `LittleHoursSettingsTests.swift`. Each test file declares its own
  private notification-center double, by existing convention.
- **The Little Hours dataset is generated, not hand-written** — `little-hours.json` comes from
  `scripts/liturgy/build-little-hours.mjs`. These three offices need no dataset entry, so that
  pipeline is untouched.

## Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Whether to notify for offices the app deliberately does not carry | Yes — notice only | "Belongs to the parish" argues against shipping the *text*, not against ringing the *bell*. The notice points at the book; it does not replace it. |
| Sunday conduct | A separate "On Sundays" toggle for these three, **default on** | Sunday is when Matins and Evensong most belong to the parish, so it is the day the call matters most. Reusing the Little Hours' switch would silence them by default — the opposite of the intent. Two toggles is the cost of the two sets meaning opposite things. |
| Notice body content | Office name + the day's liturgical designation from `OrdinariateCalendar` | Says something true about today without bundling a word of new liturgical text, and reuses the exact fields the feast notices already draw on. Fixed copy would read as nagging by the third day; a bare title is visually thin in iOS's layout. |
| Accepting the cost of daily-varying body text | Accepted | It forfeits the repeating-trigger shortcut (1 pending slot per office instead of one per office per day) and makes the 64-cap binding. A notice that names the day earns the extra slots; a notice repeating the same sentence forever does not. |
| Where the three surface in the app | Reminders screen only | Adding them to The Hours would put rows there that cannot be opened, and adding them to the week grid would change its denominator to count observance the app cannot actually observe. |
| Spelling: "Matins" or "Mattins" | **Matins** | The app tracks *Divine Worship: Daily Office, **North American Edition***, via `prayer.covert.org` — the source the existing dataset was generated from, which spells it "Morning Prayer (Matins)". "Mattins" is the Commonwealth Edition spelling and the wrong book here. The app's existing copy on screen 29 is already correct. |
| Default times | Matins 08:45, Evensong 17:30, Compline 21:00 | The first two are the published daily times of the Ordinariate of the Chair of Saint Peter community whose implementation the app already follows — sourced, not invented. Compline has no canonical clock hour in any source consulted (uniformly "before going to bed"), so 21:00 is an admitted convention and the one most likely to be changed by users. |
| Kept-hours tracking | None for these three | There is no in-app "Amen" to record, so a kept flag would have to be a self-report. Self-reported observance in the same grid as observed observance makes the grid mean two things at once. |

## Research Findings

Standard tier — web research conducted 2026-09-04.

**Naming and edition.** `prayer.covert.org` describes itself as *"an approved implementation of the
Daily Offices of Morning Prayer (Matins), Evening Prayer (Evensong), Terce, Sext, Nones, and
Compline as approved for use in the Personal Ordinariate of the Chair of Saint Peter and published
in Divine Worship: Daily Office, North American Edition."* This is the source `scripts/liturgy/`
already draws the Little Hours from, so it settles both the edition the app tracks and the spelling.
The Commonwealth Edition — used by `dwdo.uk`, `singtheoffice.com` and the UK Ordinariate — spells it
"Mattins", and is a different book with different rubrics. Sources: `prayer.covert.org`,
`ordinariate.net/divine-worship-daily-office`, `ordinariate.org.uk/our-prayer-and-liturgy`.

**Times.** The same community publishes its schedule: Morning Prayer **8:45am** and Evening Prayer
**5:30pm** Eastern, listed for all seven days including Sunday — independent corroboration of the
default-on Sunday decision. Compline is described across sources (Wikipedia, Hozana, Ascension
Press) as the office prayed *before going to bed* rather than at a canonical hour, which is why its
default is a convention rather than a citation. Sources: `prayer.covert.org`,
`en.wikipedia.org/wiki/Compline`, `hozana.org`.

**iOS scheduling practice.** Practitioner write-ups converge on one split: use a repeating calendar
trigger when the message text is fixed, and a rolling reschedule when the content changes daily —
and identify the 64-request ceiling as the usual cause of daily reminders going silent after a
couple of weeks. One notes the inverse cost of repeating triggers: skipping a single day means
tearing down the repeat and rebuilding individual requests. Both halves of that trade-off apply
here. Sources: `rorklab.net`, `alicinaroglu.dev`, `emrldlabs.com`,
`developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger`.

**Positioning.** The established Liturgy of the Hours apps — Universalis, iBreviary — compete on
completeness of bundled text across every hour. Sapientia's choice to notify for three offices
whose text it deliberately does not carry has no obvious precedent among them, which is consistent
with it being a positioning decision rather than a gap. Sources: `universalis.com`,
`ibreviary.org`, `catholicapptitude.org`.

**Caveat.** Nothing here was verified against a physical copy of *Divine Worship: Daily Office
(North American Edition)*; the naming and times rest on the approved online implementation the app
already treats as its source. Compline's default time has no source at all and is a convention.

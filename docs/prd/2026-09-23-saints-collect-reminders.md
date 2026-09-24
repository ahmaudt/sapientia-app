# Collect Reminders That Keep the Saints

Created: 2026-09-23
Author: ahmaud@gmail.com
Agent: Claude Code
Category: Feature
Status: Final
Research: Standard

## Problem Statement

Sapientia's only daily liturgical notice is the 06:00 **Feast day notice**, a single on/off toggle
that says *"The Collect of Trinity XVI awaits."* on most days. Two things are wrong with it.

First, it passes over the saints. The calendar records most saints' days as a bare
"commemoration" line with **no collect text at all** — 44 of its 58 entries — so on the memorial of
S. Dominic the app still hands the user the Sunday's collect, repeated for the sixth day running.
And the calendar holds only a fraction of the Ordinariate's saints to begin with: Our Lady of
Walsingham, the Ordinariate's own patroness, is not in it.

Second, it cannot be shaped. A layman who wants to be told the evening before that tomorrow is a
saint's day, or who wants the collect put in front of him twice a day, or only on feasts, has one
switch and one hour.

So: a collect reminder that names the day's observance plainly — *"Today: The Feast of Our Lady of
Walsingham"*, *"Tomorrow is the memorial of S. Dominic, Priest"* — carries the saint's collect on
the weekdays the saint is kept, and has settings for which days, how many times, and whether to
give notice the evening before.

## Core User Flows

### Flow 1: Setting up the collect reminder

1. User opens **Settings → Reminders** (screen 29).
2. A **The Collect** section sits alongside the office sections, reusing their row and time-picker
   treatment.
3. User turns it on and chooses:
   - **Which days** — *Every day*, *Saints' days and feasts*, or *Feasts only*.
   - **Times per day** — one to three reminders, each with its own time. One reminder at **06:00**
     is the default, matching the notice it replaces.
   - **The evening before** — off by default; when on, a time (default **20:00**).
4. Every change rebuilds pending notices immediately, with no relaunch.

### Flow 2: The morning of a memorial

1. On Saturday 8 August 2026, the memorial of S. Dominic, a notice arrives at the chosen time:
   **"Today: The memorial of S. Dominic, Priest"**, carrying S. Dominic's collect.
2. Tapping it opens Sapientia's home screen, whose feast card shows the same observance and the
   same collect — not the Sunday's.
3. If the user chose more than one time, each notice that day says the same thing.

### Flow 3: The evening before

1. With **The evening before** on, at 20:00 on 7 August the user gets
   **"Tomorrow is the memorial of S. Dominic, Priest."**
2. The evening notice is sent only when tomorrow is a named observance — a saint's day, a feast, or
   a solemnity — that passes the user's **Which days** choice. An ordinary weekday or a Sunday —
   including a Sunday on which a feast is abrogated — produces no evening notice.

### Flow 4: A saint on a day that outranks it

1. On Sunday 18 October 2026 (S. Luke), the reminder follows the rule the user chose: **the Sunday
   keeps its own collect**. The notice reads **"Today: Trinity XX"** with the Sunday collect.
2. **A feast that falls on a Sunday is abrogated.** On Sunday 29 September 2030, S. Michael and All
   Angels gives way entirely: the notice reads **"Today: Trinity XV"** with the Sunday collect, and
   makes no mention of the feast. The same applies to every observance of Feast rank or below,
   except the Feasts of the Lord.
3. Principal feasts, Holy Week and the Easter Octave keep their own collect against a saint.
4. On weekdays in Lent and Advent, the saint's collect **does** take the place of the season's.

### Flow 5: Upgrading from the Feast day notice

1. A user who had **Feast day notice** turned on updates the app.
2. Their collect reminder is on, set to *Every day*, one reminder at 06:00 — the same cadence they
   had. Nothing goes silent on upgrade.
3. The old toggle is gone from **Settings → Calendar**; the reminder lives on the Reminders screen
   with every other notice.

## Scope

### In Scope

- **The full Ordinariate calendar of saints.** The sanctorale is expanded to the Particular
  Calendar of the Personal Ordinariate of the Chair of Saint Peter as coordinated with the United
  States national calendar — the calendar the Ordinariate's published ORDO follows — including its
  own observances such as Our Lady of Walsingham (24 September).
- **A real rank for every entry**: Solemnity, Feast, Memorial, or Optional Memorial, as the ORDO
  gives it. The notice's wording depends on it.
- **A collect for every saint's day, from public-domain sources only.** Where a proper collect exists
  in a public-domain book of the Anglican tradition — the 1662 *Book of Common Prayer*, the 1928
  American *Book of Common Prayer*, or a pre-1929 Anglican missal — that text is used. Where none
  exists, the entry uses a public-domain **common of saints** collect matching the saint's class
  (martyr, bishop, doctor, virgin, abbot, holy man or woman, and so on). **Every collect records its
  source**, so provenance can be checked text by text.
- **Saints' precedence on weekdays.** On a weekday that is not protected, the saint's collect
  governs the day instead of the seasonal collect. Protected days keep their own collect: Sundays,
  principal feasts, Holy Week, and Easter Day through the Easter Octave. This includes weekdays in
  Lent and Advent, where the saint's collect replaces the season's.
- **Feasts on a Sunday are abrogated.** Any observance of Feast rank or below that falls on a
  Sunday is not kept that year: the day is simply the Sunday of its season (*Trinity XV*,
  *Epiphany III*), with that Sunday's name and collect, and the feast is not named in any notice.
  **Two classes keep precedence over the Sunday:** Solemnities, and the **Feasts of the Lord** (such
  as the Presentation, the Transfiguration and the Exaltation of the Holy Cross). The calendar
  therefore records which feasts are Feasts of the Lord, as the ORDO gives them. Of the entries the
  calendar already calls principal, this changes today's behaviour for two: the Conversion of
  S. Paul and S. Michael and All Angels.
- **Two observances on one date:** the higher rank governs; between equal ranks, the one the
  calendar lists first.
- **One collect of the day, everywhere.** The collect a reminder carries is the collect the app
  shows for that day in every other place: the home screen's feast card, the block shield's
  *Collect of the day*, and the Little Hours' *Or the Collect of the Day*. Tapping a notice must
  never show a different collect from the one it announced.
- **Notice wording that names the observance and its rank:**
  - Same day, saint or feast: *"Today: The Feast of Our Lady of Walsingham"*,
    *"Today: The memorial of S. Dominic, Priest"*, *"Today: The Solemnity of …"*. Optional memorials
    read as *"the memorial of"*: that they are optional is a rubric, not news.
  - Same day, ordinary weekday or Sunday: *"Today: Wednesday after Trinity XVI"*.
  - Evening before: *"Tomorrow is the memorial of S. Dominic, Priest."* /
    *"Tomorrow is the Feast of Our Lady of Walsingham."*
  - Wording must read correctly for names that already begin with "The" (*"the Feast of the
    Visitation of the Blessed Virgin Mary"*, not *"the Feast of The Visitation…"*).
  - Same-day notices carry the governing collect's text; the evening notice carries only the
    announcement.
- **Frequency settings**, on the Reminders screen:
  - *Which days*: **Every day** · **Saints' days and feasts** (any day whose governing observance
    comes from the calendar of saints or is a principal feast) · **Feasts only** (Feast or
    Solemnity rank).
  - *Times per day*: 1–3, each with its own time.
  - *The evening before*: on/off plus a time.
- **The Feast day notice is absorbed** by the collect reminder, and its toggle leaves Settings →
  Calendar. Users who had it on keep an equivalent reminder after upgrading (Flow 5). New users
  start with the reminder off, as the Feast day notice does today.
- **The 64-notification ceiling holds at maximum settings.** With every Little Hour, Matins,
  Evensong and Compline on, three collect reminders a day and the evening notice, the total pending
  requests stay under iOS's cap with room left for session timers. This is a hard acceptance
  requirement.
- **Session lifecycle never deletes collect reminders**, matching the promise already made for the
  office notices.

### Explicitly Out of Scope

- **Divine Worship: The Missal's own collects** — the text is in copyright, and the US bishops'
  published policy grants online use of single daily Roman Missal collects only. It could be
  revisited if written permission is obtained; until then no Divine Worship or other in-copyright
  text is bundled.
- **Choosing between several optional memorials** on one day (as `dwdo.uk` offers) — the
  precedence rule above picks one; a picker is a separate feature.
- **A days-of-the-week control** — considered and not chosen; *Which days* covers the liturgical
  cases.
- **Feast transfer** — a feast displaced by a Sunday or Holy Week is not moved to another day. This
  is an existing, documented limitation of the calendar and stays one.
- **The Canadian, Commonwealth (UK) and Australian calendars** — the app follows the North
  American Edition; their differing saints are not added.
- **The Roman calendar** — still "coming soon" in Settings and untouched here.
- **Notification actions** ("Prayed", "Snooze") — no existing notice carries them.
- **A widget, Live Activity, or the Mac target.**

## Technical Context

Statements about the code as it stands; how to build the feature is `/spec`'s to determine.

- **Calendar and precedence.** `Sapientia/Liturgy/OrdinariateCalendar.swift` resolves a date via
  `day(for:)`. Today a sanctorale entry is either `principal` (renames the day and supplies its
  collect, except on protected days: Holy Week, Easter Day, and Advent and Lent Sundays) or
  `commemoration` (adds a `commemorationText` line only). `LiturgicalDay` exposes `dayName`,
  `season`, `commemorationText` and `collect`; it carries no rank. A principal entry currently
  displaces any Sunday outside Advent and Lent, whether it is a Feast or a Solemnity.
- **The dataset.** `Sapientia/Resources/Liturgy/ordinariate-calendar.json` holds 58 sanctorale
  entries (14 principal with collects, 44 commemorations without) and the keyed temporale
  collects. It is a member of both the app and the `SapientiaShieldConfig` extension. Unlike
  `little-hours.json`, it has **no generator script**; it was committed by hand in `85a6f46`.
- **Consumers of the day's collect** that must stay coherent with the reminder:
  `Components/Dashboard/HomeScreenContent.swift` / `FeastCard.swift` (home feast card, "Read the
  Collect"), `Liturgy/ShieldContent.swift` (block shield), `Components/Office/OfficeReaderModel.swift`
  (Little Hours' collect of the day), plus `OfficeSequence.swift`, `TheHoursView.swift` and both
  office notification schedulers, which read `day(for:)` for names.
- **The notice being replaced.** `Liturgy/FeastNotificationScheduler.swift` schedules one 06:00
  notice per day over a 14-day rolling window, prefixed `feast-`, gated by
  `PrayerSettings.feastNoticeEnabled` (app-group suite `group.com.artempleton.sapientia`). Its
  toggle is in `Views/SettingsView.swift`'s Calendar section; it is rescheduled from `HomeView` and
  `HomeView+Actions`.
- **The notification budget is binding.** iOS keeps at most 64 pending local notifications per app
  and silently drops the rest. Current worst case: Little Hours 3 × 5 days = 15
  (`OfficeNotificationScheduler`), Matins/Evensong/Compline 3 × 9 days = 27
  (`DailyOfficeNotificationScheduler`, in progress, uncommitted), feast notices 14 — **56**, before
  `TimersUtil`'s session notices. The collect reminder at maximum settings needs up to 4 requests
  per day, and the notice body varies daily, so repeating triggers are not available (the same
  trade-off recorded in `docs/prd/2026-09-04-matins-evensong-compline-notices.md`).
- **Session cleanup.** `Utils/TimersUtil.swift`'s `preservedPrefixes` lists the notification prefixes
  that survive a session starting or stopping.
- **Reminders screen.** `Views/PrayerRemindersView.swift` renders screen 29;
  `Components/Office/PrayerRemindersModel.swift` holds its copy and the `RemindersEditor` single
  mutation path. Settings follow `LittleHoursSettings.swift` / `DailyOfficeSettings.swift`: app-group
  storage, times as minutes from midnight, absent keys distinguishable from zero.
- **Tests to extend:** `sapientiaTests/OfficeNotificationTests.swift`, `PrayerRemindersTests.swift`,
  and the existing calendar tests; each test file declares its own notification-center double.

## Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| When the saint's collect wins | Weekdays that aren't protected; Sundays, principal feasts, Holy Week and the Easter Octave keep their own | User's choice. It follows the liturgical ordering in which Sundays and the great days outrank memorials, while fixing the real complaint: a weekday saint losing to a Sunday collect repeated all week. |
| A feast falling on a Sunday | Abrogated; the day is the Sunday of its season, and the feast goes unmentioned | User's direction. The Sunday outranks the feast, so the feast is not kept that year and the reminder gives the Sunday alone. |
| Solemnities and Feasts of the Lord on a Sunday | Keep precedence over the Sunday | User's decision. It matches the Roman table of days, which ranks both above ordinary Sundays. Solemnities already displace ordinary Sundays today, so only ordinary Feasts change. |
| Easter Octave counts as protected | Yes | "Easter" in the chosen rule covers the whole Octave, whose days outrank every memorial. Approved at review. |
| How far the saints go | The full North American Ordinariate calendar | User's choice. Collects for only the current 44 would leave most memorials, and the Ordinariate's own patroness, missing. |
| Where the collect texts come from | Public-domain Anglican sources, with a common-of-saints collect where no proper exists | User's choice. Divine Worship's texts need written permission; public-domain texts can ship now. Common collects are the tradition's own answer for saints without a proper. |
| One collect of the day across the app | Yes | A notice announcing S. Dominic that opens onto the Sunday's collect contradicts itself. Approved at review over changing the reminder only. |
| Notice wording | "Today: The Feast of …" / "Tomorrow is the memorial of …", with rank | User's direction. Naming the rank tells the user what kind of day it is before they read the collect. |
| Frequency controls | Which days, times per day (1–3), the evening before | User's choice. Days of the week was offered and not chosen. |
| Fate of the Feast day notice | Absorbed; old users migrate to Every day at 06:00 | Same cadence they already had, so an upgrade silences nothing. Two morning notices on the same subject would compete. |
| Two observances on a date | Higher rank governs; between equals, calendar order | Deterministic without a picker; a picker is out of scope. |
| Evening-before default time | 20:00 | Before Compline's 21:00 default, so the two don't land together. Reversible. |

## Research Findings

Standard tier: web research conducted 2026-09-23.

**Rank and precedence.** *Divine Worship: The Missal* (CTS, 2015) contains the Ordinariate's
Calendar of the Church Year, then the Propers of Saints and Holy Days with a collect for each, and
operates under the General Instruction of the Roman Missal, whose table of days ranks solemnities,
feasts, memorials and optional memorials, with Sundays and the privileged seasons above memorials.
The Personal Ordinariate of the Chair of Saint Peter publishes an annual ORDO "according to the
Particular Calendar of the Personal Ordinariate … coordinated with the National Calendars of the
United States and [Canada]". Sources: `en.wikipedia.org/wiki/Divine_Worship:_The_Missal`,
`ordinariate.net/divine-worship-missal`, `scribd.com/document/1008799899/Ordinariate-ORDO`.

**Licensing.** The USCCB Committee on Divine Worship states that, apart from permission for single
daily collects from the Roman Missal, no permission is given for publishing liturgical texts on
the internet, and the Liturgy Office of England and Wales notes ICEL holds copyright for most
liturgical texts. *Divine Worship: The Missal* is a 2015 CTS publication. The Prayer Book collects
(1662; 1928 American) are public domain, but they supply propers mainly for the red-letter days:
apostles, evangelists and major feasts. That gap is why common-of-saints collects are in scope.
Sources: `usccb.org/committees/divine-worship/policies`,
`liturgyoffice.org.uk/Resources/Copyright/index.shtml`.

**Prior art.** `dwdo.uk`, a web app for the Commonwealth Edition of *Divine Worship: Daily Office*,
lists the day's optional memorials and lets the user tap one to show its office, which is
precedent for the picker left out of scope here. Source: `dwdo.uk`.

**Caveat.** The approved online office the app's datasets were generated from, `prayer.covert.org`,
did not respond during research, so it could not be checked for how it handles a saint's collect.
Nothing here was verified against a printed ORDO or a printed *Divine Worship* book. Each saint's
rank and date will come from the published ORDO when the calendar is expanded.

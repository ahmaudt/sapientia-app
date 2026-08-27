# Session log

A running summary of coding sessions, newest first. See `CLAUDE.md` for what belongs in an entry.

## 2026-08-27 — The Little Hours: Terce, Sext and None

**Shipped** (on `feature/little-hours`, not yet committed)

- The three Little Hours are prayable in the app: a bundled dataset, a paged reader on the steel
  ground, three editable reminders, a kept-hours record, and a "The Little Hours" section on Home.
  15 new source files, 8 new test files, 233 tests green.
- Fixed a real pre-existing bug: `TimersUtil` deleted *every* pending notification that wasn't
  `feast-` prefixed, so office reminders would have been wiped the moment any session started —
  contradicting what the reminders screen promises. Renamed to `cancelNonSessionNotifications` with
  a `preservedPrefixes` list.

**Decided**

- **`develop` was fast-forwarded from 2.2.1 to the redesign tip**, then pushed (first `origin/develop`).
  It was a strict ancestor of `release/1.0.0` with zero commits of its own, so nothing was lost, and
  the 2.2.1 lineage remains reachable via `main`. Branching a feature off the old `develop` would
  have meant building on a tree with no `SapientiaTheme`, no `BlueprintStage` and no `Liturgy/`.
- **The bundle is generated, not transcribed.** `offices-data.js` → `build-little-hours.mjs` →
  `little-hours.json`, with `diff-office-text.py` verifying 189 text fields against source and
  proven to fail on a dropped asterisk. Hand-typing 100+ lines of liturgy was the largest avoidable
  risk in the whole change.
- **`offices-data.js` was not complete**, contrary to the premise we started from: it carries a
  rubric naming the Angelus and Regina Coeli, not their text. Both were taken from
  `prayer.covert.org/Sext/` and are the only content with no machine-checkable original — so they
  have explicit verbatim tests, including the `✠` in the Angelus collect.
- **The Gloria is said in two different forms**, settled over several passes: unpointed and
  continuous with the responsory at the opening (same display type as "O GOD, make speed to save
  us"), and pointed with asterisks, unlabelled, after each psalm — matching the pointed verses it
  closes. The source pages print only the psalm ones; the opening Gloria was added because it is the
  traditional shape of every hour, after checking all three pages and finding it absent.
- **The reader shows more than the mockups do.** Screen 28 omits the collect intro and the
  faithful-departed prayer; both are required content, so the reader renders them and the plan
  explicitly warns against "correcting" the screen toward the design.
- **Kept-hours live in app-group `UserDefaults`**, not SwiftData — one small dated fact per hour,
  no relations, no schema to migrate. The week grid's denominator is `enabledWeekdays ×
  enabledHours`; hardcoding ×3 would show a target a user who switched an hour off can never reach.
- **Notification window is 10 days, not 14.** iOS caps pending local notifications at 64 and
  silently drops the rest; 14 days × 3 hours plus the 14 feast notices left no room for session
  timers.

**Mistakes worth remembering**

- **A truncation bug shipped past 200+ green tests and was only caught by looking at a rendering.**
  None's collect ellipsised to "who livest and reignest…" — the same `b5daecb` failure mode, and
  the same fix (`fixedSize`). Worse: the test written to guard it *passed while the bug was
  visible*, because it compared whole-page height against one block's. Measure the block, not the page.
- **Two plan defects were caught by the review agents, not by me.** The page model said 5 pages but
  described 6 (chapter and collect share a screen), and the grid denominator hardcoded ×3 while the
  settings gave each hour its own toggle.
- **Simulator tap automation via AppleScript is not trustworthy** — the window moved between runs and
  Home's layout shifted when an alert resolved, so taps landed on the wrong controls. One such
  mis-tap produced a kept hour that looked like a serious bug; temporary `NSLog` probes proved the
  code was correct. Screens 25 and 29 are rendered through `UIHostingController` in
  `OfficeSnapshotTests` instead, which is deterministic.

**Open**

- **Not verified: a notification actually firing**, and **office notices surviving a session start**
  (the latter needs Screen Time, which the simulator cannot grant). Both are unit-tested. They join
  the Task 6 device check still outstanding from the layout-pass plan — one device pass could clear
  all three.
- **Nothing is committed.** The work sits uncommitted on `feature/little-hours`.
- **Passiontide suppression of the Gloria Patri** is unimplemented: `prayer.covert.org/None/` says it
  is "restored beginning with Midafternoon Prayer on Holy Saturday" but never says where suppression
  begins, so this release always shows it.
- **The priest/deacon collect intro** ("The Lord be with you") is not shipped; only the lay form is.
- `docs/plans/` is gitignored, so the plan file does not travel with the branch.

## 2026-08-13 — Version restart to 1.0.0, onboarding fix, first TestFlight beta

**Shipped**

- `f531ad2` — Setup flow (screens 07–12) relaid out on `BlueprintStage`, tip jar removed, Acknowledgements screen added, version set to 1.0.0. Closed out the layout-pass plan.
- `b5daecb` — Fixed the opening screen truncating its three numbered steps, and bumped to build 2.
- `df25878` — Cleared the last Foqos version strings (test bundles were still 2.1.2; the About mockup still said 3.0.0).
- Branch renamed `release/3.0.0` → `release/1.0.0` and pushed to origin (first time this branch has existed remotely).
- Uploaded 1.0.0 (1) and then 1.0.0 (2) to TestFlight.
- Uncommitted at time of writing: `scripts/asc-status.rb`, `.claude/settings.json`, this log, and the CLAUDE.md sections describing them.

**Decided**

- **Version restarts at 1.0.0, not 1.0.** App Store Connect's record said "1.0" and the repo convention is `x.y.z`. Kept `1.0.0` because the branch and git tags use three components; ASC adopted the uploaded build's string automatically, since the version record was still in `PREPARE_FOR_SUBMISSION` with no build attached. No manual edit was needed after all.
- **The Mac target stays at `0.1`.** It versions independently through `release-mac.sh` and the Sparkle appcast; dragging it to 1.0.0 would misstate a released Mac app.
- **Did NOT delete and recreate the App Store Connect app record.** It was floated as a way to "start clean" at 1.0.0. Rejected: the App Store side was already clean (version record 1.0.0, `PREPARE_FOR_SUBMISSION`, never released) and the only 3.0.0 artifact was one expired TestFlight build, invisible to customers. Deleting permanently retires the bundle id `com.artempleton.sapientia`, which would force re-plumbing five targets **and a fresh Apple approval of the `com.apple.developer.family-controls` distribution entitlement** — the entitlement the whole product depends on.
- **The onboarding truncation was a layout defect, not a copy problem.** The step text is verbatim from the design. The hero block was the only flexible sibling in the outer `VStack`, so SwiftUI satisfied it first and compressed the steps, collapsing their `Text` views to one line. Fixed with `fixedSize` + `layoutPriority`, plus a scroll fallback so truncation is now structurally impossible. Verified by screenshotting the running app on a simulator matching the reporting device's resolution.

**Mistakes worth remembering**

- **Probed API permissions wrongly.** Posting a beta group with an empty name returned `409 name required`, which was read as "permission granted." Apple validates payloads *before* authorization, so the 409 never reached the auth check — a real name still returns `403`. A validation error proves nothing about permissions.
- **Expired 3.0.0 (1) before 1.0.0 cleared beta review**, which left external testers with no installable build at all and produced "No builds available." Expiry is irreversible. Sequence it the other way: get the replacement approved first.

**Open**

- **Beta review `WAITING_FOR_REVIEW`** for 1.0.0 (2). External testers get it on approval; a background poller was watching for the verdict.
- **Task 6 device check** from the layout-pass plan — the Set-aside Screen Time picker can't be exercised in the simulator (no Family Controls). Needs a pass on a real device.
- **`make lint` is broken** — the Makefile calls bare `swift-format`, which lives inside the Xcode toolchain. Use `xcrun swift-format` until fixed; `make check` is unusable meanwhile.
- **1.0.0 close-out pending** — tag `1.0.0`, merge `release/1.0.0` into `main` and back into `develop`, delete the branch. `develop` is still at 2.2.1 and has none of the redesign, so this merge-back is what unblocks future feature branches.
- **Daily Office + reminders** designed in Claude Design (project "Daily Office Prayer Reminders": `offices-data.js`; and `Sapientia Daily Office.dc.html` screens 25+). Agreed to plan it via `/spec` and to land it on a feature branch **after** 1.0.0 closes out.

**Apple/TestFlight facts worth not rediscovering**

- Every build needs its **own** Beta App Review; an earlier approval does not carry over.
- The App Store Connect API key can read TestFlight state and create/populate **internal** groups, but returns `403` for creating **external** groups and for submitting Beta App Review. Those stay manual.
- Apple forbids API keys from managing a build's **individual testers** entirely — use beta groups.
- `scripts/update-app-version.rb` forces `CURRENT_PROJECT_VERSION = 1` on a version bump (Xcode Cloud numbers builds itself). Manual uploads need `make bump-build`, added this session, now a prerequisite of `make testflight`.

# Sapientia — Project Instructions

## Session log — keep it current

**`docs/sessions.md` is a running summary of coding sessions, newest first. Append an entry before a session ends, and read the top of it when a session begins** — it is the answer to "where did we leave off?"

Write an entry whenever a session produces something worth carrying forward: shipped work, a decision with reasoning, a fix whose cause was non-obvious, or a loose end. Skip it for purely conversational sessions.

Each entry gets a `## YYYY-MM-DD — short title` heading and covers, in prose or short bullets:

- **Shipped** — what changed, with commit SHAs
- **Decided** — the choice AND the reasoning, so the next session doesn't relitigate it
- **Open** — what's unfinished, blocked, or waiting on someone else

Record the reasoning, not just the outcome. "Kept 1.0.0 rather than 1.0" is far less useful six weeks later than the same line with *why*. Be honest in the log: record what actually happened, including mistakes and their corrections — a log that only lists wins will mislead the next session.

## Git Workflow — OneFlow (develop + master variation)

**This is the default Git method for this repository.** Reference: https://www.endoflineblog.com/oneflow-a-git-branching-model-and-workflow#variation-develop-master

- **`main`** (master role): release history only. Every commit on `main` is a released version, tagged `x.y.z`. Never commit work directly to `main`.
- **`develop`**: the integration branch where all day-to-day work lands. Feature and release branches start from and return to `develop`.
- **Feature branches** (`feature/<name>`): used when implementing a new feature. Branch off `develop`, integrate back into `develop` (rebase or merge per feature), then delete.
- **Release branches** (`release/x.y.z`): branch off `develop` when preparing a release ("Release branches method"). Version bumps and release-only fixes happen here. When done: tag the release, merge into `main`, merge back into `develop`, then delete the branch.

Current release in progress: `release/1.0.0` (Sapientia rebrand + iOS redesign). Sapientia's version numbering restarts at `1.0.0` — the inherited Foqos `2.x`/`3.x` numbering does not carry over.

## App Store Connect status on session start

`.claude/settings.json` registers a `SessionStart` hook that runs `./scripts/asc-status.rb --hook`, so every new session opens knowing the current TestFlight state — latest build, processing state, internal/external distribution, and the beta review verdict — without anyone having to ask.

It is a **status read, not a poll**: two API calls, then it exits. Nothing runs in the background, and nothing waits for a verdict. To watch for a verdict, run a polling loop explicitly for that session instead.

Run it yourself any time:

```bash
./scripts/asc-status.rb          # human-readable summary
./scripts/asc-status.rb --hook   # SessionStart JSON, as the hook invokes it
```

It authenticates with the App Store Connect API key at `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8` — the same key `make testflight` uses. The key never enters the repo; only the key id and issuer id do, matching the Makefile. Override with `ASC_KEY_ID`, `ASC_ISSUER_ID`, or `ASC_APP_ID`.

**It never blocks a session.** A missing key, absent network, or API error exits 0 with no output, so a checkout without the key behaves exactly as before. Note the API key can read TestFlight state and manage internal groups, but Apple forbids it from creating external groups or submitting for Beta App Review — those stay manual in App Store Connect.

## Release version numbers

`scripts/update-app-version.rb` sets `CURRENT_PROJECT_VERSION = 1` on every version bump, because Xcode Cloud assigns build numbers itself for `make app-release`. Manual `make testflight` uploads therefore need their own bump, or App Store Connect rejects the repeated `(version, build)` pair:

```bash
make bump-build   # highest build in the project, plus one — already a prerequisite of `make testflight`
```

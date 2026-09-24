# Sapientia — Project Instructions

The single source of project guidance for agentic coding assistants working on the Sapientia iOS
app. `CLAUDE.md` includes this file rather than duplicating it, so there is one place to keep true.

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

Sapientia's version numbering restarts at `1.0.0` — the inherited Foqos `2.x`/`3.x` numbering does not carry over. Current version is **1.1.1**, shipped to TestFlight; no release branch is in progress.

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

## Build & Test Commands

This project includes a `Makefile` with common development tasks. Run `make help` to see all available commands.

### Building
```bash
# Build from command line
make build

# Clean build artifacts
make clean
```

### Running Tests
```bash
# iOS unit tests (sapientiaTests)
make test

# All tests, including UI tests
make test-all

# Mac TCP/TLS filter unit tests (SapientiaMacTests)
make mac-test
```

### Code Formatting
The project uses swift-format to maintain consistent code style. Run format commands before committing:
```bash
# Check formatting
make lint

# Fix formatting issues
make lint-fix

# Run both lint and build
make check
```

## Code Style Guidelines

### Formatting & Indentation
- **Indentation**: 2 spaces (no tabs)
- **Line width**: Prefer 100-120 characters max
- **Trailing whitespace**: Remove all trailing whitespace
- **Blank lines**: One blank line between functions, two between major sections

### Imports
- Place at the top of each file
- Group alphabetically (system frameworks first, then third-party)
- Separate groups with blank lines
- Remove unused imports

```swift
import DeviceActivity
import FamilyControls
import SwiftUI
import WidgetKit
```

### Naming Conventions
- **Types** (struct, class, enum): PascalCase
  - Views: PascalCase + "View" suffix (e.g., `HomeView`, `ActionButton`)
  - Managers: PascalCase + "Manager" suffix (e.g., `StrategyManager`)
  - Utilities: PascalCase + "Util" suffix (e.g., `TimersUtil`)
  - Models: PascalCase (e.g., `BlockedProfiles`)
- **Functions/Methods**: camelCase, verb-based (e.g., `startBlocking`, `stopBlocking`)
- **Variables/Properties**: camelCase
- **Constants**: camelCase (not UPPER_CASE)
- **Booleans**: Prefix with `is`, `has`, `enable`, `allow` (e.g., `isActive`, `hasPermission`)
- **Private properties**: camelCase, no underscore prefix
- **Static properties**: camelCase or PascalCase based on usage

### SwiftUI Patterns
- Use `@State` for local view state
- Use `@Binding` for parent-child data flow
- Use `@Environment(\.keyPath)` for environment values
- Use `@EnvironmentObject` for shared state managers
- Use `@Query` for SwiftData queries
- Prefer trailing closure syntax for view modifiers

```swift
@State private var isPresenting = false
@Environment(\.modelContext) private var context
@EnvironmentObject var strategyManager: StrategyManager
@Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]
```

### SwiftData Patterns
- Mark models with `@Model`
- Use `@Attribute(.unique)` for unique identifiers
- Use `@Relationship` for relationships between models
- Use `#Predicate` for complex queries
- Always call `context.save()` after modifications

```swift
@Model
class BlockedProfiles {
  @Attribute(.unique) var id: UUID
  @Relationship var sessions: [BlockedProfileSession] = []
}
```

### Protocols & Strategy Pattern
- Define clear protocols for extensible behavior
- Protocol methods should be minimal and focused
- Use associated types or generic constraints when appropriate
- Strategy implementations return optional views for custom UI

```swift
protocol BlockingStrategy {
  static var id: String { get }
  var name: String { get }
  func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (any View)?
  func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)?
}
```

### Error Handling
- Use `try-catch` for throwing functions
- Provide descriptive error messages for user feedback
- Use `fatalError()` only for truly unrecoverable states (e.g., ModelContainer initialization)
- Use `print()` for debugging, remove before production

```swift
do {
  try context.save()
} catch {
  errorMessage = "Failed to save changes: \(error.localizedDescription)"
}
```

### Control Flow
- Use `guard` for early returns and validation
- Prefer early returns over nested if statements
- Use optional chaining extensively
- Use nil-coalescing operator `??` for default values

```swift
guard let profile = try? BlockedProfiles.findProfile(byID: id, in: context) else {
  errorMessage = "Profile not found"
  return
}
```

### Computed Properties
- Use computed properties instead of functions when no parameters are needed
- Keep computed properties lightweight
- Avoid side effects in computed properties

```swift
var isBlocking: Bool {
  return activeSession?.isActive == true
}
```

### Closures
- Prefer trailing closure syntax
- Mark closure parameters with `@escaping` when stored
- Use weak references in closures to avoid retain cycles in classes

```swift
strategy.onSessionCreation = { [weak self] status in
  self?.handleSessionStatus(status)
}
```

### Comments
- Comments are minimal; let code be self-documenting
- Use comments to explain "why", not "what"
- Comment sections of related functionality
- Document complex business logic or workarounds

### Previews
- Include `#Preview` blocks for SwiftUI views
- Create realistic preview data
- Use separate UserDefaults for previews

```swift
#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
}
```

### Architectural Patterns
- Use singleton pattern for shared managers via `static let shared`
- Dependency injection via environment objects
- Repository-like static methods on models for data operations
- Coordinator pattern for complex flows (StrategyManager)

### File Organization
- Group related files in subdirectories (Views/, Models/, Components/, Utils/)
- One public type per file when possible
- Private types can be in same file
- Extensions on types should be in separate files or grouped logically

## Testing Best Practices
- Test public interfaces, not private implementation
- Use async/await for async operations
- Mock dependencies for unit tests
- Test both success and failure paths
- Name tests descriptively: `testGivenX_WhenY_ThenZ()`

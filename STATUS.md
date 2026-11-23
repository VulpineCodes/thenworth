# Thenworth — Status

Built Nov 22–23, 2026. Franklin picked Thenworth (green theme) on Nov
22, 2026, and told me to build it. It replaces Sy-Reality on his Apple
resume. PharmaFlow iOS is NOT the pick — leave it unpushed and unused.

## Verified results

### Financial engine — VERIFIED, independently re-run

Ran `swift test` (Swift 6.2 toolchain) in `~/workspace/portfolio/thenworth/`
twice: once after the core was built and once at the end, after the app
layer landed (the app layer does not touch the package). Final run,
Nov 23, 2026, exit 0:

- **XCTest: 66 tests, 0 failures** — FinancialEngineTests 24,
  GoalPlannerTests 9, MilestonesTests 11, ModelsTests 13,
  RetirementPlannerTests 9.
- **Swift Testing: 13 tests, 0 failures** — runs alongside XCTest under
  the same `swift test` invocation on this Linux toolchain.
- **Total: 79 tests passing, 0 failing.**

Key values (expected values computed independently in Python
closed-form and cited in the test comments): future value of $100 at
7% for 20 years, monthly compounding = $403.87; annuity of $100/month
at 7% for 20 years = $52,092.67; $2.88/month redirected for 20 years =
$1,500.27 (vs $691.20 paid); car goal ($12,000 target, $1,500 saved,
$200/month, 24 months) projects $6,860.92, shortfall $5,139.08,
months to goal 45; retirement starting at 23 vs 30 ($300/month, 5%
match capped at $150/month, retire at 65) = $958,767.79 vs
$567,332.20, a difference of $391,435.59 nominal.

### App layer — WRITTEN, NOT COMPILED

The SwiftUI layer (14 files under `App/`) was written on the Linux VM,
where SwiftUI, SwiftData, Swift Charts, WidgetKit, App Intents, and
XCUITest do not exist. **It has not been compiled and no app flow has
been run.** Do not claim otherwise. The checklist below is the
verification, run on Franklin's Mac.

The app layer was checked against the real core API (not just the
spec): all locked API names matched, and one real mismatch was found
and fixed (`GoalResult.monthsToGoal` is `Int?`, not `Int` — the detail
view now shows "More than 100 years" when it is nil).

## What was built

33 files under `~/workspace/portfolio/thenworth/` plus this handoff doc (34 total):

```
Package.swift
README.md, ARCHITECTURE.md, DESIGN.md, STATUS.md (this file),
CODEX_HANDOFF.md (collaborator handoff for ChatGPT Codex)
Sources/ThenworthCore/ (6 files)
  Models.swift, FinancialEngine.swift, GoalPlanner.swift,
  RetirementPlanner.swift, Milestones.swift, SampleScenarios.swift
Tests/ThenworthCoreTests/ (7 files)
  FinancialEngineTests.swift, GoalPlannerTests.swift,
  RetirementPlannerTests.swift, MilestonesTests.swift,
  ModelsTests.swift, TestHelpers.swift,
  FinancialEngineSwiftTests.swift (Swift Testing)
App/ (15 files)
  ThenworthApp.swift
  Models/DesignSystem.swift, Models/SwiftDataModels.swift,
    Models/ScenarioViewModel.swift, Models/LearnContent.swift
  Views/HomeView.swift, Views/FutureLensView.swift,
    Views/ScenarioDetailView.swift, Views/MyFuturesView.swift,
    Views/LearnWhyView.swift, Views/Components.swift
  UITests/ThenworthUITests.swift (5 XCUITest tests, Mac only)
  Widget/ThenworthWidget.swift (WidgetKit, Mac only)
  AppIntents/ThenworthIntents.swift (App Intent + AppShortcut)
  README.md (Xcode setup for all four targets + manual checklist)
```

Phase 1 core is built: the engine, the four scenarios, the Future
Lens, local persistence, Learn Why, the widget, the intent, and the
tests. No GitHub repo exists; nothing was pushed (Franklin creates the
repo).

## What Franklin must do on his Mac

Full steps are in `App/README.md`. Summary:

1. **App target:** New iOS App project named Thenworth, SwiftUI,
   SwiftData, deployment target iOS 17. Add the `thenworth` folder as a
   local package dependency; add `ThenworthCore` to the app target.
   Copy the `App/` files into the app target (app target:
   `ThenworthApp.swift`, `Models/`, `Views/`,
   `AppIntents/ThenworthIntents.swift`).
2. **UI test target:** New UI Testing Bundle named
   `ThenworthUITests`; add `UITests/ThenworthUITests.swift`; Product >
   Test (5 tests).
3. **Widget extension + App Group:** New Widget Extension target
   named `ThenworthWidget`; replace its starter files with
   `Widget/ThenworthWidget.swift`; add `Models/SwiftDataModels.swift`,
   `Models/DesignSystem.swift`, `Views/Components.swift` and
   `ThenworthCore` to the widget target. Add the App Groups capability
   with group `group.com.franklin.thenworth` on BOTH the app and widget
   targets, **before the first launch** if possible (the app falls back
   to a private SwiftData store when the group is missing, and scenarios
   saved there do not move to the shared store on their own).
4. **App Intents:** no extra setup; the shortcut appears in Shortcuts
   once the app has run.
5. **Run the manual checklist** in `App/README.md`: app launches with
   three tabs; four sample cards with live previews; detail opens;
   scrubbing updates chart, figures, and milestone together; the
   dollars toggle works (today's dollars is the default); assumptions
   are editable with the "hypothetical, not guaranteed" note visible;
   save/reopen/edit/delete in My Futures; compare two scenarios of the
   same kind; Learn Why lists four topics; Dark Mode, largest Dynamic
   Type, Reduce Motion, and VoiceOver all behave; the widget shows a
   saved scenario's future value in today's dollars; the Shortcuts
   intent returns a value; all five UI tests pass.

### SwiftUI APIs to check first on the Mac

These are the APIs the app-layer author was least sure exist exactly
as written on iOS 17. Check them first if the build fails:

- `AreaMark` with `yStart:`/`yEnd:` for shading between two series,
  and `AxisValueLabel(format: .currency(code:).precision(...))` in
  Charts.
- `.contentTransition(.numericText())` on the counting figures.
- `ModelConfiguration(schema:groupContainer:isStoredInMemoryOnly:)` and
  `ModelContainer(for:configurations:)` with an App Group.
- Widget `.containerBackground(_:for: .widget)` and
  `TimelineProvider` + `StaticConfiguration` as written.
- App Intents `Summary("What is $\(\.$amount) worth in \(\.$years) years?")`
  parameter-summary interpolation and `AppShortcut` phrases using
  `\(.applicationName)`.
- `#Predicate { $0.id == scenario.id }` capturing a local UUID in
  `ScenarioStore`.
- XCUITest finding `NavigationLink`s as `app.buttons[...]` via the
  accessibility identifiers, and
  `app.segmentedControls["dollars-toggle"]` finding the segmented
  `Picker`.

## Known limits

- The app layer, widget, and UI tests were written but NOT compiled or
  run here. The Mac checklist is the verification.
- The "spend now" path in the Future Lens is held flat at the purchase
  amount (you got the thing, worth what you paid). It does not model
  resale or depreciation; the "How this is calculated" section says so.
- All projections are hypothetical under the assumptions the user sets.
  Nothing here is financial advice, and the app does not diagnose or
  treat any condition.
- Money is `Double` dollars — fine for projections, not a ledger.
- No account, no backend, no bank integrations, no money movement.
  Offline-first, local-only storage, synthetic sample data only.
- No ARKit or RealityKit, deliberately — not relevant to a finance app.
  The author's VR work covers the spatial angle.

## Next steps (not done)

- Mac validation above (compile, simulator flows, UI tests, widget,
  Shortcuts).
- Phase 2 polish: animations, onboarding, haptics, shareable scenario
  summaries, more visual milestones, optional notifications the user
  explicitly enables.
- Phase 3: housing/mortgage, job offers and cities, deeper retirement,
  behavioral-science learning features, iCloud sync.
- GitHub repo (Franklin creates it), README screenshots once the app
  runs, and the Apple resume with Thenworth replacing Sy-Reality.

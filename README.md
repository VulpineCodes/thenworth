# Thenworth

**Make tomorrow feel real.**

Thenworth is a native iOS app that helps people visualize the long-term
financial consequences of decisions they make today. Its core question:
*What is today's decision worth to your future self?*

This is not a budgeting app, an expense tracker, an investment platform,
or an AI financial chatbot. It compares two or more hypothetical
financial futures based on choices you can make today, and shows the
tradeoff in seconds.

The product is grounded in ideas from cognitive psychology (temporal
discounting, future-self continuity, delayed gratification), but it does
not diagnose anything, treat anything, or predict anyone's future. The
psychology informs the design; it is not a marketing claim.

## What it does

Four core scenarios, each with a signature **Future Lens**: a fork
visualization where two paths diverge from the decision point and the gap
between them is shaded. The gap IS the tradeoff. A timeline scrubber
moves the horizon; figures count up as you scrub; a toggle switches
between today's dollars (the default) and future dollars; a concrete
milestone line translates the gap into something tangible
("that's about a used car").

1. **One-time purchase** — spend $100 today, or let it grow? (Spend now /
   Let it grow.)
2. **Recurring expenses** — a $2.88/month subscription, and what
   redirecting it could accumulate. (Keep paying / Redirect it.)
3. **Save toward a goal** — target price, current savings, monthly
   redirect, target date; shortfall and timeline. (Your plan / Target.)
4. **Early vs late retirement** — start at 23 vs 30, with contribution
   amounts and employer match shown separately from growth.
   (Start at 30 / Start at 23.)

Thenworth never shames spending. Every scenario says plainly what
spending gives you today, because that is real value too.

## Technologies

| Framework | Where | What for |
| --- | --- | --- |
| SwiftUI | `App/ThenworthApp.swift`, `App/Views/` | All UI, `TabView`, `NavigationStack`, sheets |
| Swift Charts | `App/Views/FutureLensView.swift` | Fork chart: two `LineMark`s, an `AreaMark` for the shaded gap, a `RuleMark` for the scrubbed year |
| SwiftData | `App/Models/SwiftDataModels.swift` | Local-only storage of saved scenarios (My Futures) |
| Combine | `App/Models/ScenarioViewModel.swift` | Reactive state: scrubbed year + dollars basis + inputs combine into one derived lens computation |
| WidgetKit | `App/Widget/ThenworthWidget.swift` | Home-screen widget showing a saved scenario's future value |
| App Intents | `App/AppIntents/ThenworthIntents.swift` | One Shortcuts/Siri intent ("What is it worth in N years?") plus an `AppShortcut` |
| XCTest | `Tests/ThenworthCoreTests/` | Engine tests (66 tests) |
| Swift Testing | `Tests/ThenworthCoreTests/FinancialEngineSwiftTests.swift` | Engine tests in the Swift Testing style (13 tests) |
| XCUITest | `App/UITests/ThenworthUITests.swift` | UI tests for Home-to-scenario, timeline scrub, save, dollars toggle, Learn Why |

Not used, deliberately: ARKit and RealityKit. They are not relevant to a
finance app; the author's VR work covers the spatial angle.

## Quick start

### Financial engine (runs on this machine)

Requires Swift 6.2. The portable core is a Swift package with no UI
dependency.

```sh
cd thenworth
~/swift/swift-6.2-RELEASE-ubuntu24.04/usr/bin/swift test
```

On a Mac with Xcode installed, `swift test` works the same way, or run
the tests from Xcode.

**Verified:** 79 tests passing, 0 failing (66 XCTest + 13 Swift Testing),
independently re-run Nov 23, 2026. See `STATUS.md`.

### The app (needs a Mac with Xcode)

The SwiftUI layer is written but was **not compiled** on the Linux
machine where it was built (no Xcode; SwiftUI, SwiftData, Charts,
WidgetKit, App Intents, and XCUITest are not in the Linux Swift
toolchain). Full setup for all four targets (app, UI tests, widget
extension + App Group, intents), a manual validation checklist, and the
known limits are in `App/README.md`.

## Financial assumptions

All calculations come from the deterministic `ThenworthCore` engine.
No AI invents numbers.

- **Default assumptions:** 7% hypothetical annual return, 3% annual
  inflation, monthly compounding. The user can edit all three.
- **Hypothetical, not guaranteed.** Investment growth is always labeled
  hypothetical. Cash savings use a 0% return.
- **Today's dollars vs future dollars.** Every projection reports both:
  the nominal (future-dollar) value and the inflation-adjusted
  (today's-dollar) value. The app defaults to today's dollars.
- **What is counted separately:** money contributed, employer match,
  hypothetical growth, total future nominal value, inflation-adjusted
  value. A goal's shortfall is the target minus the projected value.
- **Formulas:** future value `FV = P(1 + r/n)^(nt)`; monthly annuity
  uses the effective monthly rate implied by the compounding frequency;
  real value `nominal / (1 + inflation)^years`. See
  `ARCHITECTURE.md` for the full list.
- **Edge cases handled:** zero principal, zero rate, zero years,
  negative inputs (clamped to 0), 100-year horizons.

## Limitations

- Projections are hypothetical illustrations under the assumptions the
  user sets. Nothing here is financial advice, and the app does not
  diagnose or treat any condition (including ADHD).
- The "spend now" path is held flat at the purchase amount (you got the
  thing, worth what you paid). It does not model resale or
  depreciation; the "How this is calculated" section in the app says so.
- Money is `Double` dollars. That is fine for projections and
  visualizations; it is not a ledger.
- The app layer was written but not compiled here. The Mac checklist in
  `App/README.md` is the verification.

## Privacy

Offline-first. No account, no backend, no bank integrations, no money
movement. Saved scenarios live locally in SwiftData (shared with the
widget through an App Group). Sample data is synthetic.

## Project structure

```
Package.swift                    ThenworthCore package (engine + tests)
Sources/ThenworthCore/            Financial engine and models (no UI dependency)
  Models.swift                    Assumptions, projections, scenarios, Sendable value types
  FinancialEngine.swift           Future value, annuity, real value, projections, comparison
  GoalPlanner.swift               Goal projections (shortfall, months to goal)
  RetirementPlanner.swift         Early vs late retirement with employer match
  Milestones.swift                Concrete translations ("about a used car")
  SampleScenarios.swift           Prebuilt synthetic demo scenarios
Tests/ThenworthCoreTests/         XCTest (66) + Swift Testing (13)
App/                              SwiftUI app layer (Xcode project source, not in the package)
  ThenworthApp.swift              @main, ModelContainer, TabView
  Models/                         Design system, SwiftData models, Combine view model, Learn content
  Views/                          Home, Future Lens, Scenario Detail, My Futures, Learn Why, components
  UITests/                        XCUITest UI tests (Mac only)
  Widget/                         WidgetKit widget (extension target, Mac only)
  AppIntents/                     App Intent + AppShortcut
  README.md                       Xcode setup for all four targets + manual checklist
ARCHITECTURE.md                   How the layers fit together
DESIGN.md                         The green design system
STATUS.md                         Verified results and exactly what needs the Mac
```

## Status and roadmap

Phase 1 (core) is built: the engine, the four scenarios, the Future
Lens, local persistence, Learn Why, the widget, the intent, and the
tests. See `STATUS.md` for what is verified and what still needs the
Mac. Phase 2 (polish, widgets, App Intents, haptics, shareable
summaries) and Phase 3 (housing, job offers, deeper retirement, iCloud
sync) are documented in the brief and in `STATUS.md`; none of them is
claimed as done.

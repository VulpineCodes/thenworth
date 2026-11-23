# Thenworth — Codex handoff

This document explains everything built so far, so an AI coding
collaborator (ChatGPT Codex) can pick the project up and extend it
without guessing. Read `README.md`, `ARCHITECTURE.md`, `DESIGN.md`,
and `STATUS.md` alongside this file; they are the project's own docs
and this file summarizes them for a collaborator.

## 1. What Thenworth is

A native iOS app that helps people visualize the long-term financial
consequences of decisions they make today. Tagline: *Make tomorrow
feel real.* Core question: *What is today's decision worth to your
future self?*

It is NOT a budgeting app, expense tracker, investment platform, or AI
financial chatbot. It compares two or more hypothetical financial
futures based on choices you can make today and shows the tradeoff in
seconds. The product is grounded in ideas from cognitive psychology
(temporal discounting, future-self continuity, delayed gratification),
but it does not diagnose anything, treat anything, or predict anyone's
future. The psychology informs the design; it is not a marketing claim.

**Why it exists (portfolio goal):** Franklin is a Vanderbilt CS +
Cognitive Psychology student (class of 2027) targeting 2027 new-grad
software engineering roles, especially Apple's Evolve rotation program.
Thenworth replaces Sy-Reality on his Apple resume. It must demonstrate
strong Swift/SwiftUI fundamentals, thoughtful architecture, mathematical
correctness, robust testing, and the Apple frameworks those job
postings look for. Do not manufacture performance results, test
coverage, user counts, or impact metrics.

**Theme:** green. Deep forest green primary, warm ivory backgrounds,
one bright growth-green accent. Not generic fintech neon green.

## 2. Architecture (two layers)

```
thenworth/
  Package.swift                  Swift package "ThenworthCore" (the engine)
  Sources/ThenworthCore/          Deterministic financial engine + models
  Tests/ThenworthCoreTests/       XCTest (66) + Swift Testing (13)
  App/                            SwiftUI app layer (Xcode project source)
  README.md  ARCHITECTURE.md  DESIGN.md  STATUS.md  CODEX_HANDOFF.md
```

- **ThenworthCore** is a Swift package with NO UI dependency. It is
  the only place numbers come from. It compiles and tests on Linux
  (Swift 6.2) and on a Mac. All model types are `Sendable` (Swift 6
  strict concurrency). Package: `Package.swift`, swift-tools 6.0,
  platforms macOS 14 / iOS 17, one library product `ThenworthCore`.
- **App/** is the SwiftUI layer. It depends on ThenworthCore and adds
  SwiftUI, Swift Charts, SwiftData, Combine, WidgetKit, App Intents,
  and XCUITest. It is written but NOT compiled (no Xcode on the Linux
  machine where it was built). See section 9.

## 3. The financial engine (ThenworthCore)

All calculations are deterministic. No AI invents numbers. All returns
are hypothetical and always labeled hypothetical, never guaranteed.

### API (in `Sources/ThenworthCore/FinancialEngine.swift`)

- `FinancialEngine.futureValue(principal:annualRate:years:compounding:)`
  — lump sum, `FV = P(1 + r/n)^(nt)`.
- `FinancialEngine.futureValueOfAnnuity(monthlyPayment:annualRate:years:compounding:)`
  — equal monthly contributions at end of each month. The monthly rate
  is the effective monthly rate implied by the annual rate and
  compounding frequency: `(1 + r/n)^(n/12) - 1`. Zero rate returns the
  plain sum of contributions.
- `FinancialEngine.realValue(nominal:annualInflation:years:)`
  — today's dollars: `nominal / (1 + inflation)^years`.
- `FinancialEngine.totalPaid(monthlyAmount:years:)` — total paid for a
  recurring monthly cost, no return.
- `FinancialEngine.redirectedValue(...)` — same as the annuity, named
  for the redirect use case.
- `FinancialEngine.project(principal:monthlyContribution:annualRate:annualInflation:years:compounding:stepYears:)`
  — returns a `Projection` (sampled points plus final nominal, final
  real, total contributions, total growth). Each point separates
  contributions from growth.
- `FinancialEngine.compare(_:_:)` — side-by-side `Comparison` of two
  projections, with nominal and real differences.
- `GoalPlanner.plan(target:currentSavings:monthlyRedirect:annualRate:annualInflation:targetMonths:compounding:)`
  — returns `GoalResult` (`target`, `currentSavings`,
  `monthlyRedirect`, `targetMonths`, `projectedAtTargetDate`,
  `projectedRealAtTargetDate`, `shortfall`, `onTrack`, `monthsToGoal`
  which is `Int?`, nil when unreachable).
- `RetirementPlanner.compare(...)` — early vs late start, returns
  `RetirementComparison` with `early` and `late` (`RetirementSide`:
  `startAge`, `finalNominal`, `finalReal`) plus `differenceNominal`
  and `differenceReal`. User contributions, employer match, and growth
  are kept as separate figures.
- `Milestones.translation(for:)` — takes a dollar gap, returns a
  `String?` translating it into a concrete comparison
  ("about a used car").
- `Models.swift` — `Assumptions` (memberwise init; static `.default`
  = 7% return / 3% inflation / monthly compounding, and `.cash`),
  `CompoundingFrequency` (`annually`, `quarterly`, `monthly`, `daily`,
  with `.periodsPerYear`), `ScenarioKind` (String-backed enum: `oneTime`,
  `recurring`, `goal`, `retirement`), `ScenarioInputs` (`Codable`,
  memberwise init, `var` fields; `years` is `Double`; `targetMonths`,
  `earlyStartAge`, `lateStartAge`, `retirementAge` are `Int`s),
  `SavedScenario` (memberwise init
  `(id:kind:title:inputs:createdAt:updatedAt:)`, `Identifiable` via
  `id`), `SampleScenarios.all` (`[SavedScenario]`).

### Rules the engine follows

- Negative money, rate, inflation, and time inputs clamp to 0.
- Zero rate or zero years returns the principal unchanged.
- Cash savings use a 0% return; invested savings use the hypothetical
  return the user sets.
- Every projection reports both nominal (future dollars) and
  inflation-adjusted (today's dollars) values. The app defaults to
  today's dollars.
- Contributions, employer match, hypothetical growth, total future
  nominal value, and inflation-adjusted value are always distinguished.
- Money is `Double` dollars. Fine for projections; not a ledger.

### Verified values (checked against independent Python closed-form calculations, cited in the test comments)

- $100 at 7% for 20 years, monthly compounding = **$403.87**
- $100/month annuity at 7% for 20 years = **$52,092.67**
- $2.88/month redirected for 20 years = **$1,500.27** (vs $691.20 paid)
- Car goal ($12,000 target, $1,500 saved, $200/month, 24 months):
  projects $6,860.92, shortfall $5,139.08, months to goal 45
- Retirement starting at 23 vs 30 ($300/month, 5% match capped at
  $150/month, retire at 65) = **$958,767.79 vs $567,332.20**,
  difference $391,435.59 nominal

### Tests

- **79 tests passing, 0 failing** (66 XCTest + 13 Swift Testing),
  independently re-run Nov 23, 2026. Run with:
  `~/swift/swift-6.2-RELEASE-ubuntu24.04/usr/bin/swift test`
  (on a Mac with Xcode, `swift test` works the same way).
- Breakdown: FinancialEngineTests 24, GoalPlannerTests 9,
  MilestonesTests 11, ModelsTests 13, RetirementPlannerTests 9
  (XCTest); FinancialEngineSwiftTests 13 (Swift Testing).
- Edge cases tested: zero inputs, negative inputs (clamped), 100-year
  horizons, unreachable goals (nil months to goal), cash vs invested.

## 4. The four scenarios

1. **One-time purchase** — spend $100 today, or let it grow?
   Paths: "Spend now" / "Let it grow."
2. **Recurring expenses** — a $2.88/month subscription, and what
   redirecting it could accumulate. Paths: "Keep paying" /
   "Redirect it."
3. **Save toward a goal** — target price, current savings, monthly
   redirect, target date; shortfall and timeline. Paths: "Your plan" /
   "Target."
4. **Early vs late retirement** — start at 23 vs 30, with contribution
   amounts and employer match shown separately from growth. Paths:
   "Start at 30" / "Start at 23."

## 5. The Future Lens (signature interaction)

The fork visualization: two paths diverge from the decision point and
the gap between them is shaded. The gap IS the tradeoff. Implemented
in `App/Views/FutureLensView.swift` with Swift Charts: two `LineMark`s,
an `AreaMark` for the shaded gap, a `RuleMark` for the scrubbed year.

- A big thumb-friendly timeline scrubber; figures count up and down
  live as you drag it (animated counting gated by reduced motion).
- A today's-dollars vs future-dollars toggle, defaulting to today's
  dollars.
- A concrete-milestone line translating the gap ("that's about a used
  car", "that's 3 months of rent").
- Non-judgmental copy: neutral path labels and a line acknowledging
  what spending gives you today ("Spending gets you the thing today.
  That's real value too."). The app explains opportunity cost; it never
  shames spending.
- The "spend now" path is held flat at the purchase amount (you got
  the thing, worth what you paid). It does not model resale or
  depreciation; the "How this is calculated" section says so.

## 6. Design system (green)

Documented in `DESIGN.md`. Tokens in `App/Models/DesignSystem.swift`:

- Deep forest primary `#1E4D38`, forest deep `#14382A`, growth-green
  accent `#2E8B57`, warm ivory background `#FAF6EC`, card `#FFFDF6`,
  with dark-mode variants for every token.
- Rounded system fonts; money formatter showing cents under $100.
- Light and dark mode, Dynamic Type, VoiceOver labels, reduced-motion
  support. No excessive glass effects, no generic dashboard cards, no
  gamification, no chatbot.

## 7. Apple frameworks used (for the resume)

| Framework | Where | What for |
| --- | --- | --- |
| SwiftUI | `App/ThenworthApp.swift`, `App/Views/` | All UI, `TabView`, `NavigationStack`, sheets |
| Swift Charts | `App/Views/FutureLensView.swift` | Fork chart (two `LineMark`s, `AreaMark` gap, `RuleMark`) |
| SwiftData | `App/Models/SwiftDataModels.swift` | Local-only storage of saved scenarios (My Futures) |
| Combine | `App/Models/ScenarioViewModel.swift` | Reactive state: scrubbed year + dollars basis + inputs combine into one derived lens, so chart, figures, and milestone can never disagree |
| WidgetKit | `App/Widget/ThenworthWidget.swift` | Home-screen widget showing a saved scenario's future value (App Group `group.com.franklin.thenworth`) |
| App Intents | `App/AppIntents/ThenworthIntents.swift` | One Shortcuts/Siri intent ("What is it worth in N years?") plus an `AppShortcut` |
| XCTest | `Tests/ThenworthCoreTests/` | Engine tests (66) |
| Swift Testing | `Tests/ThenworthCoreTests/FinancialEngineSwiftTests.swift` | Engine tests in Swift Testing style (13) |
| XCUITest | `App/UITests/ThenworthUITests.swift` | UI tests: Home to scenario, timeline scrub, save a future, dollars toggle, Learn Why (5 tests, Mac only) |

Not used, deliberately: ARKit and RealityKit. They are not relevant to
a finance app; Franklin's VR work (Wallace Lab, Sy-Reality) covers the
spatial angle.

## 8. File map (34 files)

```
Package.swift
README.md  ARCHITECTURE.md  DESIGN.md  STATUS.md  CODEX_HANDOFF.md (this file)
Sources/ThenworthCore/ (6)
  Models.swift  FinancialEngine.swift  GoalPlanner.swift
  RetirementPlanner.swift  Milestones.swift  SampleScenarios.swift
Tests/ThenworthCoreTests/ (7)
  FinancialEngineTests.swift  GoalPlannerTests.swift
  RetirementPlannerTests.swift  MilestonesTests.swift
  ModelsTests.swift  TestHelpers.swift
  FinancialEngineSwiftTests.swift
App/ (16)
  ThenworthApp.swift
  Models/DesignSystem.swift  Models/SwiftDataModels.swift
  Models/ScenarioViewModel.swift  Models/LearnContent.swift
  Views/HomeView.swift  Views/FutureLensView.swift
  Views/ScenarioDetailView.swift  Views/MyFuturesView.swift
  Views/LearnWhyView.swift  Views/Components.swift
  UITests/ThenworthUITests.swift
  Widget/ThenworthWidget.swift
  AppIntents/ThenworthIntents.swift
  README.md
```

App-layer files and what each holds (also in `App/README.md`):

- `ThenworthApp.swift` — `@main` entry, `ModelContainer` (App Group
  store with private fallback), root `TabView`.
- `Models/DesignSystem.swift` — green design system, type scale,
  money formatting.
- `Models/SwiftDataModels.swift` — `SavedScenarioEntity` (inputs as
  JSON), `ScenarioStore` (fetch/save/delete/seed), `ThenworthAppGroup`
  identifier.
- `Models/ScenarioViewModel.swift` — Combine view model for one
  detail screen; `LensCalculator` builds the fork data from the core.
- `Models/LearnContent.swift` — educational content: compounding,
  opportunity cost, inflation, temporal discounting.
- `Views/HomeView.swift` — "What does today mean for tomorrow?",
  sample scenario cards with live previews, start-from-scratch.
- `Views/FutureLensView.swift` — the fork chart, timeline scrubber,
  animated counting numbers, dollars toggle, milestone line.
- `Views/ScenarioDetailView.swift` — per-kind inputs, editable
  assumptions, live results, "How this is calculated", Save.
- `Views/MyFuturesView.swift` — saved scenarios list,
  swipe-to-delete, compare two of the same kind.
- `Views/LearnWhyView.swift` — Learn Why list and detail.
- `Views/Components.swift` — shared components (stat row, path chip,
  dollars toggle, milestone line, assumption row) plus scenario
  headline helpers.
- `UITests/ThenworthUITests.swift` — 5 XCUITest tests (Mac only).
- `Widget/ThenworthWidget.swift` — WidgetKit widget (Mac only).
- `AppIntents/ThenworthIntents.swift` — future-value intent +
  AppShortcut.
- `App/README.md` — Xcode setup for all four targets + manual
  checklist.

## 9. What is NOT verified (read this before changing the app layer)

The SwiftUI layer, widget, and XCUITest tests were written but **not
compiled or run** on the Linux machine (no Xcode; SwiftUI, SwiftData,
Charts, WidgetKit, App Intents, and XCUITest are not in the Linux
Swift toolchain). Do not claim the app compiles until it is built on a
Mac.

SwiftUI APIs to check first on the Mac (listed in `STATUS.md` and
`App/README.md`): `AreaMark` with `yStart:`/`yEnd:` and the currency
axis-label format in Charts, `.contentTransition(.numericText())`,
`ModelConfiguration` with an App Group, widget
`.containerBackground(_:for: .widget)`, App Intents parameter-summary
interpolation, `#Predicate` capturing a local UUID, and XCUITest
finding `NavigationLink`s as buttons.

The app layer was checked against the real core API and one real
mismatch was found and fixed (`GoalResult.monthsToGoal` is `Int?`, not
`Int`). The locked core API assumptions are listed in `App/README.md`
under "Assumptions about the core API"; check them first if the Mac
build fails.

## 10. How to build on a Mac (Xcode)

Full steps are in `App/README.md`; summary:

1. **App target:** New iOS App project named Thenworth, SwiftUI,
   SwiftData, deployment target iOS 17. Add the `thenworth` folder as a
   local package dependency; add `ThenworthCore` to the app target.
   Copy the `App/` files into the app target (app target:
   `ThenworthApp.swift`, `Models/`, `Views/`,
   `AppIntents/ThenworthIntents.swift`).
2. **UI test target:** New UI Testing Bundle named
   `ThenworthUITests`; add `UITests/ThenworthUITests.swift`; Product >
   Test (5 tests).
3. **Widget extension + App Group:** New Widget Extension target named
   `ThenworthWidget`; replace its starter files with
   `Widget/ThenworthWidget.swift`; add `Models/SwiftDataModels.swift`,
   `Models/DesignSystem.swift`, `Views/Components.swift`, and
   `ThenworthCore` to the widget target. Add the App Groups capability
   with group `group.com.franklin.thenworth` on BOTH the app and widget
   targets, **before the first launch** if possible (the app falls back
   to a private SwiftData store without it, and scenarios saved there
   do not move to the shared store on their own).
4. **App Intents:** no extra setup; the shortcut appears in Shortcuts
   once the app has run.
5. **Run the manual checklist** in `App/README.md`: three tabs, four
   cards with live previews, scrub/toggle/save/compare flows, Dark
   Mode, largest Dynamic Type, Reduce Motion, VoiceOver, widget,
   Shortcuts intent, all five UI tests.

## 11. Conventions and rules for collaborators

- **The engine is the source of truth for numbers.** Never compute a
  financial figure in a view. Never let AI generate a number; all
  calculations come from `ThenworthCore`.
- **Hypothetical, not guaranteed.** Investment growth is always labeled
  hypothetical. Nothing is financial advice. No diagnosis or treatment
  claims (including ADHD). No misleading comparisons.
- **Non-judgmental copy.** Explain opportunity cost; never shame
  spending. Every scenario states what spending gives you today.
- **Privacy-first, offline-first.** No account, no backend, no bank
  integrations, no money movement. Saved scenarios live locally in
  SwiftData (shared with the widget through an App Group). Sample data
  is synthetic.
- **Tests before claims.** Do not claim a test passes, a feature works,
  or the app compiles unless you ran it. Run `swift test` for the
  engine; the Mac checklist in `App/README.md` is the verification
  for the app layer.
- **Keep the layers separate.** Engine and models stay UI-free and
  testable. New scenarios go through `ScenarioKind` + the core
  planners, not through view code.
- **No ARKit/RealityKit** in this app (not relevant); Franklin's VR
  work covers the spatial angle.
- **No empty commits, no backdating, no fabricated metrics.** Keep
  the git history honest.

## 12. Roadmap

- **Phase 1 (done):** engine, four scenarios, Future Lens, local
  persistence, Learn Why, widget, intent, tests.
- **Phase 2 (not done):** animations, onboarding, haptics, shareable
  scenario summaries, more visual milestones, optional notifications
  the user explicitly enables.
- **Phase 3 (not done):** housing/mortgage, job offers and cities,
  deeper retirement, behavioral-science learning features, iCloud sync.
- **GitHub:** no repo exists yet. Franklin creates it; then this
  project is pushed to it. README screenshots come once the app runs.

## 13. How to collaborate on this snapshot

There is no GitHub repo yet, so this archive is the current snapshot.
If you are Codex working from this archive: make your changes, run
`swift test` for the engine, list exactly what you changed and what
you verified, and flag anything that needs a Mac (Xcode) to confirm.
Do not push anywhere and do not create a repo; Franklin creates the
repo and the project is pushed to it. Once the repo exists, work
directly on it (branch, commit, pull request) and keep the history
honest.

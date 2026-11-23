# Thenworth Architecture

## Overview

Thenworth has two layers with a hard boundary between them:

```
┌─────────────────────────────────────────────────────────┐
│  Xcode app layer (App/)                                 │
│  SwiftUI + Swift Charts + SwiftData + Combine +         │
│  WidgetKit + App Intents + XCUITest                     │
│  (written, NOT compiled on the Linux VM — see STATUS.md)│
└──────────────────────┬──────────────────────────────────┘
                       │ imports ThenworthCore
┌──────────────────────▼──────────────────────────────────┐
│  ThenworthCore (Swift package)                          │
│  Deterministic financial engine + models. No UI, no    │
│  network, no persistence dependency. Fully tested.      │
└─────────────────────────────────────────────────────────┘
```

The core is a Swift package (`Package.swift`, swift-tools 6.0,
macOS 14 / iOS 17) with one library target and one test target. The app
layer is an Xcode project source tree; it is not part of the package.
That split is what makes the engine independently testable on Linux
and keeps the widget, the intent, and the app all reading the same
numbers from the same code.

## ThenworthCore (the engine)

### Models (`Sources/ThenworthCore/Models.swift`)

All value types, all `Sendable` (Swift 6 strict concurrency — the
static presets required it), all `Codable` where they are persisted.

- `CompoundingFrequency`: annually, quarterly, monthly, daily, with
  `periodsPerYear` (1, 4, 12, 365).
- `Assumptions`: `annualReturn` (hypothetical), `annualInflation`,
  `compounding`. `.default` is 7% return / 3% inflation / monthly;
  `.cash` is 0% return / 3% inflation / monthly.
- `ProjectionPoint` / `Projection`: a timeline series. Every point
  carries `nominal` (future dollars), `real` (today's dollars),
  `contributions` (money put in), and `growth` (nominal minus
  contributions). The two dollar bases are never conflated.
- `GoalResult`: target, current savings, monthly redirect, target
  months, projected value at the target date (nominal and real),
  `shortfall`, `onTrack`, and `monthsToGoal` (`Int?`, nil when the goal
  is unreachable with the given redirect).
- `RetirementSide` / `RetirementComparison`: each side keeps
  `contributions` (user), `employerMatch`, and `growth` as separate
  figures, plus final nominal and real values. The comparison reports
  the difference between starting early and starting late.
- `ScenarioKind`, `ScenarioInputs`, `SavedScenario`: the four scenario
  kinds (oneTime, recurring, goal, retirement); inputs are one struct
  with optional fields per kind plus `assumptions`; a saved scenario is
  an id, a kind, a title, inputs, and timestamps.
- `SampleScenarios.all`: four prebuilt synthetic demo scenarios (the
  $100 one-time purchase, $2.88/month iCloud, the $12,000 car goal,
  retirement at 23 vs 30).

### Engine (`FinancialEngine.swift`, `GoalPlanner.swift`, `RetirementPlanner.swift`)

Pure functions, deterministic, no AI, no randomness.

- `FinancialEngine.futureValue(principal:annualRate:years:compounding:)`
  — `FV = P(1 + r/n)^(nt)`.
- `FinancialEngine.futureValueOfAnnuity(monthlyPayment:annualRate:years:compounding:)`
  — monthly contributions at the end of each period, using the
  effective monthly rate implied by the compounding frequency.
- `FinancialEngine.realValue(nominal:annualInflation:years:)` —
  `nominal / (1 + inflation)^years`.
- `FinancialEngine.totalPaid(monthlyAmount:years:)` — the raw cost of
  a recurring payment over a horizon.
- `FinancialEngine.project(principal:monthlyContribution:annualRate:annualInflation:years:compounding:stepYears:)`
  — a full `Projection` series at the requested step (default 1 year).
- `FinancialEngine.redirectedValue(...)` and
  `FinancialEngine.compare(_:_:)` — small helpers that build the two
  paths of a comparison and return a `Comparison` struct, so the UI can
  show two paths side by side.
- `GoalPlanner.plan(...)` — projects current savings plus the monthly
  redirect to the target date, then searches month by month (up to
  1,200 months) for when the target is reached.
- `RetirementPlanner.compare(...)` — builds both sides from the same
  monthly contribution, applying the employer match as
  `min(contribution × matchRate, matchCapMonthly)` and keeping the
  match separate from user contributions and from growth.

Edge-case rules, tested: negative inputs clamp to 0; years = 0 returns
the principal/contributions; a zero rate returns plain sums; 100-year
horizons stay finite. Money is `Double` dollars — fine for projections
and visualizations, not a ledger.

### Milestones (`Milestones.swift`)

`Milestones.translation(for:)` maps a dollar gap to a short concrete
string ("about a used car", "about 3 months of rent"). Pure and
deterministic, so it is testable. It is the piece that makes the future
tangible; the thresholds are US-anchored and deliberately ordinary.

## App layer (SwiftUI)

### Entry and navigation (`ThenworthApp.swift`)

`@main` app with a SwiftData `ModelContainer` (App Group store with a
private fallback — see below) and a three-tab `TabView`: Home, My
Futures, Learn Why. Scenario detail opens as a sheet/navigation
destination from Home or My Futures.

### State and the Future Lens (`Models/ScenarioViewModel.swift`, `Views/FutureLensView.swift`)

`ScenarioViewModel` is an `ObservableObject` that uses **Combine**
because it genuinely helps here: three independent sources (the
scenario inputs, the dollars basis, the scrubbed year) feed one derived
computation. `Publishers.CombineLatest3($inputs, $basis, $scrubbedYear)`
maps through `LensCalculator.compute(...)` into a single published
`lens`, so the chart, the figures, and the milestone line can never
disagree. State that is simpler without Combine (titles, navigation,
save confirmation) stays plain.

`LensCalculator` is a pure function over core inputs. It builds the
fork for each scenario kind:

- One-time: first path flat at the purchase amount ("Spend now"), second
  path the future value ("Let it grow").
- Recurring: first path the cumulative amount paid ("Keep paying"),
  second path the annuity value ("Redirect it").
- Goal: first path the projected savings ("Your plan"), second path the
  flat target ("Target").
- Retirement: first path the late start, second path the early start,
  both as annuity values from their start ages.

The "spend" path is held flat at the purchase amount: you got the thing,
worth what you paid. It does not model resale or depreciation, and the
"How this is calculated" section says so.

`FutureLensView` draws the fork with Swift Charts (two `LineMark`s, an
`AreaMark` shading the gap, a `RuleMark` at the scrubbed year), a large
slider plus year steppers, animated counting numbers (gated by reduced
motion), a today's-dollars/future-dollars toggle defaulting to today's
dollars, and the milestone line. Path labels are neutral, and each
scenario carries one short acknowledgment line ("Spending gets you the
thing today. That is real value too.").

### Persistence (`Models/SwiftDataModels.swift`)

`SavedScenarioEntity` is a SwiftData `@Model` that stores a
`SavedScenario` with its inputs encoded as JSON. `ScenarioStore` wraps
the `ModelContext` (fetch, save, update, delete) and seeds
`SampleScenarios.all` on first launch if the store is empty. The store
uses App Group `group.com.franklin.thenworth` so the widget can read
the same scenarios; if the group capability is not added yet, the app
falls back to a private store (scenarios saved there do not move to the
shared store on their own — add the group before first launch).

### Widget and intents

- `Widget/ThenworthWidget.swift` (WidgetKit, extension target): a
  static-configuration widget showing the most recently updated saved
  scenario's future value in today's dollars, reading the shared
  SwiftData store through the App Group.
- `AppIntents/ThenworthIntents.swift` (App Intents, app target): one
  intent, `WorthInYearsIntent` (amount + years, computed by the core
  under the default assumptions, returned in today's dollars), plus one
  `AppShortcut`.

### UI tests (`UITests/ThenworthUITests.swift`)

Five XCUITest tests in a UI Testing target (Mac only): Home to a
scenario, timeline scrub, save a future, dollars toggle, Learn Why.
Controls carry accessibility identifiers so the tests can find them.

### Design system (`Models/DesignSystem.swift`)

See `DESIGN.md`. Deep forest green primary, warm ivory backgrounds, one
bright growth-green accent, explicit light and dark variants, rounded
system fonts, a money formatter that shows cents under $100 (a $2.88
subscription matters) and whole dollars above.

## Technologies

| Framework | Where | What for |
| --- | --- | --- |
| SwiftUI | `App/ThenworthApp.swift`, `App/Views/` | All UI |
| Swift Charts | `App/Views/FutureLensView.swift` | Fork chart and gap shading |
| SwiftData | `App/Models/SwiftDataModels.swift` | Local-only saved scenarios |
| Combine | `App/Models/ScenarioViewModel.swift` | One derived lens from three inputs |
| WidgetKit | `App/Widget/ThenworthWidget.swift` | Home-screen widget |
| App Intents | `App/AppIntents/ThenworthIntents.swift` | Intent + AppShortcut |
| XCTest | `Tests/ThenworthCoreTests/` | Engine tests (66) |
| Swift Testing | `Tests/ThenworthCoreTests/FinancialEngineSwiftTests.swift` | Engine tests (13) |
| XCUITest | `App/UITests/ThenworthUITests.swift` | UI tests (5, Mac only) |

Not used, deliberately: ARKit and RealityKit. They are not relevant to
a finance app; the author's VR work covers the spatial angle.

## Testing strategy

- Engine: 79 tests (66 XCTest + 13 Swift Testing), all run under one
  `swift test` invocation on Linux and on a Mac. Expected values were
  computed independently in Python closed-form and are cited in the
  test comments. Edge cases (zero, negative, 100-year, unreachable
  goals) are covered.
- App layer: no automated tests run on Linux (SwiftUI is not in the
  Linux toolchain). The five XCUITest tests and the manual checklist in
  `App/README.md` are the verification, run on the Mac.
- Verification honesty: nothing is claimed as working unless it was
  run. The app layer, the widget, and the UI tests are explicitly
  uncompiled/unrun here. See `STATUS.md`.

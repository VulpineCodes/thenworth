# Thenworth App (Xcode layer)

SwiftUI + SwiftData app shell around the portable `ThenworthCore`
package. **This layer is written, not compiled**: there is no Xcode on
the Linux machine where it was written. Franklin compiles and runs it
on his MacBook.

Thenworth helps people visualize the long-term financial consequences
of today's decisions: "What does today mean for tomorrow?" The
signature interaction is the Future Lens, a fork visualization where
two paths diverge from the decision point and the gap between them is
shaded. The gap IS the tradeoff.

## Technologies used (for the resume and README)

| Framework | Where | What for |
| --- | --- | --- |
| SwiftUI | `ThenworthApp.swift`, all `Views/` | App UI, `TabView`, `NavigationStack`, sheets |
| SwiftData | `Models/SwiftDataModels.swift` | Local-only storage of saved scenarios |
| Swift Charts | `Views/FutureLensView.swift` | Fork chart: two `LineMark`s, an `AreaMark` for the shaded gap, a `RuleMark` for the scrubbed year |
| Combine | `Models/ScenarioViewModel.swift` | Reactive state: the scrubbed year, dollars basis, and scenario inputs combine into one derived lens computation |
| WidgetKit | `Widget/ThenworthWidget.swift` | Home-screen widget showing a saved scenario's future value |
| App Intents | `AppIntents/ThenworthIntents.swift` | One Shortcuts/Siri intent ("What is it worth in N years?") plus an `AppShortcut` |
| XCTest / XCUITest | `UITests/ThenworthUITests.swift` | UI tests for Home-to-scenario, timeline scrub, save, dollars toggle, Learn Why |

Not used, deliberately: ARKit and RealityKit. They are not relevant
to a finance app; Franklin's VR work covers the spatial angle.

## What is here

| File | Contents |
| --- | --- |
| `ThenworthApp.swift` | `@main` entry, `ModelContainer` (App Group store with private fallback), root `TabView` |
| `Models/DesignSystem.swift` | Green design system: forest green primary, warm ivory backgrounds, growth-green accent, light + dark variants, type scale, money formatting |
| `Models/SwiftDataModels.swift` | `SavedScenarioEntity` (inputs as JSON), `ScenarioStore` (fetch/save/delete/seed), `ThenworthAppGroup` identifier |
| `Models/ScenarioViewModel.swift` | Combine view model for one detail screen; `LensCalculator` builds the fork data from the core |
| `Models/LearnContent.swift` | Educational content: compounding, opportunity cost, inflation, temporal discounting |
| `Views/HomeView.swift` | "What does today mean for tomorrow?", sample scenario cards with live previews, start-from-scratch |
| `Views/FutureLensView.swift` | The fork chart, timeline scrubber, animated counting numbers, dollars toggle, milestone line |
| `Views/ScenarioDetailView.swift` | Per-kind inputs, editable assumptions, live results, "How this is calculated", Save |
| `Views/MyFuturesView.swift` | Saved scenarios list, swipe-to-delete, compare two of the same kind |
| `Views/LearnWhyView.swift` | Learn Why list and detail |
| `Views/Components.swift` | Shared components (stat row, path chip, dollars toggle, milestone line, assumption row) plus scenario headline helpers |
| `UITests/ThenworthUITests.swift` | UI tests (UI Testing target, Mac only) |
| `Widget/ThenworthWidget.swift` | Home-screen widget (Widget Extension target, Mac only) |
| `AppIntents/ThenworthIntents.swift` | Future-value intent + AppShortcut (app target) |

## Xcode setup

### 1. App target

1. File > New > Project > iOS App. Name `Thenworth`, interface
   SwiftUI, language Swift, storage SwiftData. Deployment target iOS 17.
2. File > Add Package Dependencies > Add Local > select the
   `thenworth` folder (the package root, where `Package.swift`
   lives). Add `ThenworthCore` to the app target.
3. Copy every `.swift` file under `App/` into the app target,
   **except** `UITests/`, `Widget/`, and `AppIntents/` is included:
   - App target: `ThenworthApp.swift`, `Models/`, `Views/`,
     `AppIntents/ThenworthIntents.swift`.
   - UI Testing target: `UITests/ThenworthUITests.swift` (step 2).
   - Widget Extension target: `Widget/ThenworthWidget.swift` (step 3).
4. Build and run. Everything works in the simulator; no camera, no
   network, no account.

### 2. UI test target

1. File > New > Target > UI Testing Bundle, name it
   `ThenworthUITests`.
2. Add `UITests/ThenworthUITests.swift` to that target.
3. Product > Test. The tests find controls by accessibility
   identifiers (listed at the top of the test file).

### 3. Widget extension + App Group

1. File > New > Target > Widget Extension, name it
   `ThenworthWidget`. When Xcode offers a starter widget, replace its
   files with `Widget/ThenworthWidget.swift`.
2. Add these app-target files to the widget target's membership too
   (the widget needs them to read the store and render):
   `Models/SwiftDataModels.swift`, `Models/DesignSystem.swift`,
   `Views/Components.swift`. Add `ThenworthCore` to the widget target.
3. Signing & Capabilities, on **both** the app target and the widget
   target: add the App Groups capability with the group
   `group.com.franklin.thenworth` (see `ThenworthAppGroup.identifier`
   in `Models/SwiftDataModels.swift`). Add the group **before the
   first launch** if you can: the app falls back to a private store
   when the group is missing, and scenarios saved in the private store
   do not move to the shared store on their own.
4. Build the widget target and add the widget to the home screen from
   the simulator or a device.

### 4. App Intents

No extra setup. `AppIntents/ThenworthIntents.swift` is in the app
target; the shortcut appears in Shortcuts once the app has run on a
device or simulator. Say "What is it worth in Thenworth" to Siri, or
add it in Shortcuts.

## Manual checklist (no automated app tests yet)

- [ ] App launches; the three tabs appear (Home, My Futures, Learn Why).
- [ ] Home shows four sample cards, each with a live preview line.
- [ ] Tap a card; the detail opens with inputs, assumptions, results,
      and the Future Lens.
- [ ] Scrub the timeline; the chart, figures, and milestone line update
      together. Stepper buttons move one year at a time.
- [ ] Flip the dollars toggle; values change between today's dollars
      and future dollars (today's is the default).
- [ ] Change an assumption (e.g. return to 0%); the projection updates
      and the "hypothetical, not guaranteed" note is visible.
- [ ] Save a scenario; it appears in My Futures. Reopen it, edit, save
      again; the edit sticks. Swipe to delete; it disappears.
- [ ] In My Futures, tap Compare, pick two scenarios of the same kind;
      the sheet shows both final values side by side.
- [ ] Learn Why lists four topics; each opens a plain-language explainer.
- [ ] Dark Mode on: backgrounds stay ivory-dark, text stays readable,
      the chart stays legible.
- [ ] Dynamic Type at the largest size: no clipped text in cards or the
      lens figures.
- [ ] Reduce Motion on: scrubbing updates figures without the counting
      animation.
- [ ] VoiceOver on Home and in the Lens: the chart reads its summary,
      the slider announces the year.
- [ ] Widget: after adding the App Group, save a scenario, add the
      widget; it shows that scenario's future value in today's dollars.
- [ ] Shortcuts: "What is it worth in Thenworth" returns a value in
      today's dollars under the default assumptions.
- [ ] Run the UI test target; all five tests pass.

## Assumptions about the core API (check first if the Mac build fails)

The app layer was written against the locked core API while the core
was still being built in parallel, so these are the points most likely
to need a one-line fix at compile time:

- `ScenarioInputs` is `Codable`, has a memberwise initializer, and its
  fields are `var`s (needed for the JSON storage and the Combine
  key-path bindings). `years` is a `Double`; `targetMonths`,
  `earlyStartAge`, `lateStartAge`, `retirementAge` are `Int`s;
  money and rates are `Double`s.
- `SavedScenario` has a memberwise initializer
  `(id:kind:title:inputs:createdAt:updatedAt:)` and is `Identifiable`
  via `id`.
- `ScenarioKind` is a `String`-backed enum with cases `oneTime`,
  `recurring`, `goal`, `retirement`, and `SampleScenarios.all` is
  `[SavedScenario]`.
- `Milestones.translation(for:)` takes a `Double` (the dollar gap) and
  returns `String?`.
- `Assumptions` has a memberwise initializer and static `.default`
  (7% return / 3% inflation / monthly) and `.cash`.
- `CompoundingFrequency` cases are `annually`, `quarterly`, `monthly`,
  `daily`, with `.periodsPerYear`.
- `FinancialEngine.futureValue(principal:annualRate:years:compounding:)`,
  `.futureValueOfAnnuity(monthlyPayment:annualRate:years:compounding:)`,
  `.realValue(nominal:annualInflation:years:)`,
  `.totalPaid(monthlyAmount:years:)`,
  `.project(principal:monthlyContribution:annualRate:annualInflation:years:compounding:stepYears:)`
  take `Double` years.
- `GoalPlanner.plan(target:currentSavings:monthlyRedirect:annualRate:annualInflation:targetMonths:compounding:)`
  takes `Int` targetMonths; `RetirementPlanner.compare(...)` takes
  `Int` ages.
- `GoalResult` exposes `target`, `currentSavings`, `monthlyRedirect`,
  `targetMonths`, `projectedAtTargetDate`,
  `projectedRealAtTargetDate`, `shortfall`, `onTrack`, `monthsToGoal`.
- `RetirementComparison` exposes `early` and `late` (`RetirementSide`
  with `startAge`, `finalNominal`, `finalReal`) plus
  `differenceNominal` and `differenceReal`.

## Known limits

- This layer was written but **NOT compiled** on the Linux VM
  (no Xcode; SwiftUI, SwiftData, Charts, WidgetKit, App Intents, and
  XCUITest are not in the Linux Swift toolchain). The checklist above
  is the verification.
- The widget and UI tests are Mac-only by nature; neither has run.
- The "spend now" path in the Future Lens is held flat at the purchase
  amount (you got the thing, worth what you paid). It does not model
  resale or depreciation; the "How this is calculated" section says so.
- All projections are hypothetical under the assumptions the user sets.
  Nothing here is financial advice, and the app does not diagnose or
  treat any condition.
- Privacy: offline-first, no account, no backend, local-only storage,
  synthetic sample data only.

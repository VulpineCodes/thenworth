import Combine
import Foundation
import SwiftUI
import ThenworthCore

// MARK: - Lens data (the fork visualization, as plain data)
//
// The Future Lens draws two paths from one decision point and shades the
// gap between them. These types are the data behind that drawing, so the
// chart, the figures, and the widget can all agree on the same numbers.

/// One year on the fork: the value of each path at that year.
struct LensPoint: Identifiable {
    let year: Int
    /// First path: "Spend now" / "Keep paying" / "Your plan" / "Start later".
    let first: Double
    /// Second path: "Let it grow" / "Redirect it" / "Target" / "Start earlier".
    let second: Double

    var id: Int { year }
    var lower: Double { min(first, second) }
    var upper: Double { max(first, second) }
}

/// Everything the Future Lens needs to render for one scenario, one
/// dollars basis, and one scrubbed year.
struct LensComputation {
    let points: [LensPoint]
    let maxYears: Int
    let firstLabel: String
    let secondLabel: String
    let selectedYear: Int
    let selectedFirst: Double
    let selectedSecond: Double
    /// The gap between the paths at the scrubbed year. The gap IS the tradeoff.
    var selectedGap: Double { abs(selectedSecond - selectedFirst) }
    /// Concrete translation of the gap, e.g. "about a used car".
    let milestone: String?
    /// One short, non-judgmental line about what the first path gives you.
    let acknowledgment: String

    var finalFirst: Double { points.last?.first ?? 0 }
    var finalSecond: Double { points.last?.second ?? 0 }
    var finalGap: Double { abs(finalSecond - finalFirst) }
}

// MARK: - Lens math (pure function over core inputs)

enum LensCalculator {
    /// Build the fork for a scenario. All numbers come from the core.
    /// `basis` picks today's dollars (real, the default) or future dollars
    /// (nominal). The "spend" path is held flat at the purchase amount:
    /// you got the thing, worth what you paid for it.
    static func compute(
        inputs: ScenarioInputs,
        basis: DollarBasis,
        selectedYear: Double
    ) -> LensComputation {
        let assumptions = inputs.assumptions
        switch inputs.kind {
        case .oneTime:
            let amount = inputs.amount ?? 100
            let years = max(1, Int((inputs.years ?? 20).rounded()))
            let points = (0...years).map { year in
                let nominal = FinancialEngine.futureValue(
                    principal: amount,
                    annualRate: assumptions.annualReturn,
                    years: Double(year),
                    compounding: assumptions.compounding
                )
                return LensPoint(year: year, first: amount, second: adjusted(nominal, at: year, basis: basis, inflation: assumptions.annualInflation))
            }
            return finish(
                points: points, maxYears: years, selectedYear: selectedYear,
                firstLabel: "Spend now", secondLabel: "Let it grow",
                acknowledgment: "Spending gets you the thing today. That is real value too."
            )

        case .recurring:
            let monthly = inputs.monthlyAmount ?? 2.88
            let years = max(1, Int((inputs.years ?? 20).rounded()))
            let points = (0...years).map { year in
                let paid = FinancialEngine.totalPaid(monthlyAmount: monthly, years: Double(year))
                let nominal = FinancialEngine.futureValueOfAnnuity(
                    monthlyPayment: monthly,
                    annualRate: assumptions.annualReturn,
                    years: Double(year),
                    compounding: assumptions.compounding
                )
                return LensPoint(
                    year: year,
                    first: adjusted(paid, at: year, basis: basis, inflation: assumptions.annualInflation),
                    second: adjusted(nominal, at: year, basis: basis, inflation: assumptions.annualInflation)
                )
            }
            return finish(
                points: points, maxYears: years, selectedYear: selectedYear,
                firstLabel: "Keep paying", secondLabel: "Redirect it",
                acknowledgment: "The subscription gives you something every month. That is real value too."
            )

        case .goal:
            let target = inputs.targetAmount ?? 1_000
            let current = inputs.currentSavings ?? 0
            let monthly = inputs.monthlyRedirect ?? 100
            let months = max(1, Int(inputs.targetMonths ?? 12))
            let years = max(1, Int(ceil(Double(months) / 12.0)))
            let points = (0...years).map { year in
                let principalValue = FinancialEngine.futureValue(
                    principal: current,
                    annualRate: assumptions.annualReturn,
                    years: Double(year),
                    compounding: assumptions.compounding
                )
                let annuityValue = FinancialEngine.futureValueOfAnnuity(
                    monthlyPayment: monthly,
                    annualRate: assumptions.annualReturn,
                    years: Double(year),
                    compounding: assumptions.compounding
                )
                let projected = principalValue + annuityValue
                return LensPoint(
                    year: year,
                    first: adjusted(projected, at: year, basis: basis, inflation: assumptions.annualInflation),
                    second: target
                )
            }
            return finish(
                points: points, maxYears: years, selectedYear: selectedYear,
                firstLabel: "Your plan", secondLabel: "Target",
                acknowledgment: "A goal is a plan, not a test. The numbers show the distance, not a verdict."
            )

        case .retirement:
            let early = Int(inputs.earlyStartAge ?? 23)
            let late = Int(inputs.lateStartAge ?? 30)
            let retire = Int(inputs.retirementAge ?? 65)
            let monthly = inputs.monthlyContribution ?? 200
            let effectiveMonthly = monthly + min(
                monthly * (inputs.employerMatchRate ?? 0),
                inputs.employerMatchCapMonthly ?? 0
            )
            let span = max(1, retire - early)
            let points = (0...span).map { offset in
                let earlyValue = valueAt(
                    startAge: early, offset: offset, effectiveMonthly: effectiveMonthly,
                    assumptions: assumptions, basis: basis
                )
                let lateValue = valueAt(
                    startAge: late, offset: offset - (late - early),
                    effectiveMonthly: effectiveMonthly,
                    assumptions: assumptions, basis: basis
                )
                return LensPoint(year: offset, first: lateValue, second: earlyValue)
            }
            return finish(
                points: points, maxYears: span, selectedYear: selectedYear,
                firstLabel: "Start at \(late)", secondLabel: "Start at \(early)",
                acknowledgment: "Starting later still beats never starting. The comparison shows the cost of waiting, not a judgment."
            )
        }
    }

    /// Value of a retirement path that starts at `startAge`, `offset` years in.
    /// Negative offsets mean the path has not started yet, so the value is zero.
    private static func valueAt(
        startAge: Int,
        offset: Int,
        effectiveMonthly: Double,
        assumptions: Assumptions,
        basis: DollarBasis
    ) -> Double {
        guard offset >= 0 else { return 0 }
        let nominal = FinancialEngine.futureValueOfAnnuity(
            monthlyPayment: effectiveMonthly,
            annualRate: assumptions.annualReturn,
            years: Double(offset),
            compounding: assumptions.compounding
        )
        return adjusted(nominal, at: offset, basis: basis, inflation: assumptions.annualInflation)
    }

    /// Convert a nominal (future-dollar) value to today's dollars when the
    /// basis asks for it; leave it alone for future dollars.
    private static func adjusted(
        _ nominal: Double,
        at year: Int,
        basis: DollarBasis,
        inflation: Double
    ) -> Double {
        switch basis {
        case .real:
            return FinancialEngine.realValue(
                nominal: nominal,
                annualInflation: inflation,
                years: Double(year)
            )
        case .nominal:
            return nominal
        }
    }

    private static func finish(
        points: [LensPoint],
        maxYears: Int,
        selectedYear: Double,
        firstLabel: String,
        secondLabel: String,
        acknowledgment: String
    ) -> LensComputation {
        let clampedYear = max(0, min(maxYears, Int(selectedYear.rounded())))
        let point = points[clampedYear]
        return LensComputation(
            points: points,
            maxYears: maxYears,
            firstLabel: firstLabel,
            secondLabel: secondLabel,
            selectedYear: clampedYear,
            selectedFirst: point.first,
            selectedSecond: point.second,
            milestone: Milestones.translation(for: abs(point.second - point.first)),
            acknowledgment: acknowledgment
        )
    }
}

// MARK: - ScenarioViewModel (Combine)
//
// The reactive state for one scenario detail screen. The user edits inputs
// and scrubs the timeline; Combine derives the lens from those publishers
// so the chart, the figures, and the milestone line can never disagree.
//
// Combine is used here because it genuinely helps: three independent
// inputs (the scenario inputs, the dollars basis, the scrubbed year) feed
// one derived computation. Plain @State would need manual recomputation
// in every edit site. State that is simpler without Combine (titles,
// navigation, save confirmation) stays plain.

final class ScenarioViewModel: ObservableObject {
    // Inputs the user edits.
    @Published var title: String
    @Published var inputs: ScenarioInputs
    // The scrubbed timeline year, driven by the slider and steppers.
    @Published var scrubbedYear: Double
    // Today's dollars (real) or future dollars (nominal).
    @Published var basis: DollarBasis = .real
    /// Derived by Combine from inputs + basis + scrubbedYear.
    @Published private(set) var lens: LensComputation

    let id: UUID
    let kind: ScenarioKind
    let createdAt: Date

    private var cancellables = Set<AnyCancellable>()

    init(scenario: SavedScenario) {
        self.id = scenario.id
        self.kind = scenario.kind
        self.title = scenario.title
        self.inputs = scenario.inputs
        self.createdAt = scenario.createdAt
        let initialMax = LensCalculator.compute(
            inputs: scenario.inputs, basis: .real, selectedYear: 0
        ).maxYears
        self.scrubbedYear = Double(initialMax)
        self.lens = LensCalculator.compute(
            inputs: scenario.inputs, basis: .real, selectedYear: Double(initialMax)
        )

        // Derive the lens whenever any of its three sources changes.
        Publishers.CombineLatest3($inputs, $basis, $scrubbedYear)
            .map { inputs, basis, year in
                LensCalculator.compute(inputs: inputs, basis: basis, selectedYear: year)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] computation in
                self?.lens = computation
            }
            .store(in: &cancellables)
    }

    /// The scenario as it stands now, for saving. `updatedAt` is stamped
    /// by the caller at save time.
    var currentScenario: SavedScenario {
        SavedScenario(
            id: id,
            kind: kind,
            title: title,
            inputs: inputs,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// A two-way binding to one optional input field, with a default when
    /// the core stores nil. Used by the detail form's text fields and
    /// steppers so every edit flows through the Combine pipeline above.
    func binding<Value>(
        for keyPath: WritableKeyPath<ScenarioInputs, Value?>,
        default defaultValue: Value
    ) -> Binding<Value> {
        Binding(
            get: { self.inputs[keyPath: keyPath] ?? defaultValue },
            set: { self.inputs[keyPath: keyPath] = $0 }
        )
    }

    /// A two-way binding to the assumptions struct.
    var assumptionsBinding: Binding<Assumptions> {
        Binding(
            get: { self.inputs.assumptions },
            set: { self.inputs.assumptions = $0 }
        )
    }

    /// Goal result for the current inputs, when this is a goal scenario.
    var goalResult: GoalResult? {
        guard kind == .goal else { return nil }
        return GoalPlanner.plan(
            target: inputs.targetAmount ?? 1_000,
            currentSavings: inputs.currentSavings ?? 0,
            monthlyRedirect: inputs.monthlyRedirect ?? 100,
            annualRate: inputs.assumptions.annualReturn,
            annualInflation: inputs.assumptions.annualInflation,
            targetMonths: Int(inputs.targetMonths ?? 12),
            compounding: inputs.assumptions.compounding
        )
    }

    /// Retirement comparison for the current inputs, when this is a
    /// retirement scenario.
    var retirementComparison: RetirementComparison? {
        guard kind == .retirement else { return nil }
        return RetirementPlanner.compare(
            earlyStartAge: Int(inputs.earlyStartAge ?? 23),
            lateStartAge: Int(inputs.lateStartAge ?? 30),
            retirementAge: Int(inputs.retirementAge ?? 65),
            monthlyContribution: inputs.monthlyContribution ?? 200,
            annualReturn: inputs.assumptions.annualReturn,
            annualInflation: inputs.assumptions.annualInflation,
            employerMatchRate: inputs.employerMatchRate ?? 0,
            employerMatchCapMonthly: inputs.employerMatchCapMonthly ?? 0,
            compounding: inputs.assumptions.compounding
        )
    }
}

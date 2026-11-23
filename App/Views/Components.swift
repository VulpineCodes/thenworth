import SwiftUI
import ThenworthCore

// MARK: - Shared types

/// Which dollars the figures are shown in. Real (today's dollars) is the
/// default everywhere, because it is the easier one to feel.
enum DollarBasis: String, CaseIterable {
    case real
    case nominal

    var label: String {
        switch self {
        case .real: return "Today's $"
        case .nominal: return "Future $"
        }
    }
}

// MARK: - ScenarioKind display

extension ScenarioKind {
    var displayTitle: String {
        switch self {
        case .oneTime: return "One purchase"
        case .recurring: return "Monthly expenses"
        case .goal: return "Save for something"
        case .retirement: return "My retirement"
        }
    }

    var subtitle: String {
        switch self {
        case .oneTime: return "What one purchase today could become"
        case .recurring: return "What a monthly payment adds up to"
        case .goal: return "Whether the plan reaches the target"
        case .retirement: return "What starting earlier is worth"
        }
    }

    var systemImage: String {
        switch self {
        case .oneTime: return "bag.fill"
        case .recurring: return "arrow.clockwise.circle.fill"
        case .goal: return "target"
        case .retirement: return "leaf.fill"
        }
    }
}

// MARK: - SavedScenario helpers (headlines and blank scenarios)

extension SavedScenario {
    /// Final nominal (future-dollar) value of the "grow" path at the end
    /// of the scenario's horizon. Used for list headlines and compare.
    var finalNominal: Double {
        switch kind {
        case .oneTime:
            FinancialEngine.futureValue(
                principal: inputs.amount ?? 100,
                annualRate: inputs.assumptions.annualReturn,
                years: inputs.years ?? 20,
                compounding: inputs.assumptions.compounding
            )
        case .recurring:
            FinancialEngine.futureValueOfAnnuity(
                monthlyPayment: inputs.monthlyAmount ?? 2.88,
                annualRate: inputs.assumptions.annualReturn,
                years: inputs.years ?? 20,
                compounding: inputs.assumptions.compounding
            )
        case .goal:
            GoalPlanner.plan(
                target: inputs.targetAmount ?? 1_000,
                currentSavings: inputs.currentSavings ?? 0,
                monthlyRedirect: inputs.monthlyRedirect ?? 100,
                annualRate: inputs.assumptions.annualReturn,
                annualInflation: inputs.assumptions.annualInflation,
                targetMonths: Int(inputs.targetMonths ?? 12),
                compounding: inputs.assumptions.compounding
            ).projectedAtTargetDate
        case .retirement:
            RetirementPlanner.compare(
                earlyStartAge: Int(inputs.earlyStartAge ?? 23),
                lateStartAge: Int(inputs.lateStartAge ?? 30),
                retirementAge: Int(inputs.retirementAge ?? 65),
                monthlyContribution: inputs.monthlyContribution ?? 200,
                annualReturn: inputs.assumptions.annualReturn,
                annualInflation: inputs.assumptions.annualInflation,
                employerMatchRate: inputs.employerMatchRate ?? 0,
                employerMatchCapMonthly: inputs.employerMatchCapMonthly ?? 0,
                compounding: inputs.assumptions.compounding
            ).early.finalNominal
        }
    }

    /// Final value in today's dollars.
    var finalReal: Double {
        switch kind {
        case .oneTime, .recurring:
            FinancialEngine.realValue(
                nominal: finalNominal,
                annualInflation: inputs.assumptions.annualInflation,
                years: inputs.years ?? 20
            )
        case .goal:
            GoalPlanner.plan(
                target: inputs.targetAmount ?? 1_000,
                currentSavings: inputs.currentSavings ?? 0,
                monthlyRedirect: inputs.monthlyRedirect ?? 100,
                annualRate: inputs.assumptions.annualReturn,
                annualInflation: inputs.assumptions.annualInflation,
                targetMonths: Int(inputs.targetMonths ?? 12),
                compounding: inputs.assumptions.compounding
            ).projectedRealAtTargetDate
        case .retirement:
            RetirementPlanner.compare(
                earlyStartAge: Int(inputs.earlyStartAge ?? 23),
                lateStartAge: Int(inputs.lateStartAge ?? 30),
                retirementAge: Int(inputs.retirementAge ?? 65),
                monthlyContribution: inputs.monthlyContribution ?? 200,
                annualReturn: inputs.assumptions.annualReturn,
                annualInflation: inputs.assumptions.annualInflation,
                employerMatchRate: inputs.employerMatchRate ?? 0,
                employerMatchCapMonthly: inputs.employerMatchCapMonthly ?? 0,
                compounding: inputs.assumptions.compounding
            ).early.finalReal
        }
    }

    /// One-line headline for cards and lists, in today's dollars.
    var headlineText: String {
        switch kind {
        case .oneTime:
            "\(MoneyFormat.currency(inputs.amount ?? 100)) today could be about \(MoneyFormat.currency(finalReal)) in \(MoneyFormat.yearsLabel(inputs.years ?? 20)), in today's dollars."
        case .recurring:
            let paid = FinancialEngine.totalPaid(
                monthlyAmount: inputs.monthlyAmount ?? 2.88,
                years: inputs.years ?? 20
            )
            return "\(MoneyFormat.currency(inputs.monthlyAmount ?? 2.88)) a month is \(MoneyFormat.currency(paid)) paid over \(MoneyFormat.yearsLabel(inputs.years ?? 20)). Redirected, it could be about \(MoneyFormat.currency(finalReal))."
        case .goal:
            let result = GoalPlanner.plan(
                target: inputs.targetAmount ?? 1_000,
                currentSavings: inputs.currentSavings ?? 0,
                monthlyRedirect: inputs.monthlyRedirect ?? 100,
                annualRate: inputs.assumptions.annualReturn,
                annualInflation: inputs.assumptions.annualInflation,
                targetMonths: Int(inputs.targetMonths ?? 12),
                compounding: inputs.assumptions.compounding
            )
            if result.onTrack {
                return "On track: about \(MoneyFormat.currency(result.projectedRealAtTargetDate)) by the target date, in today's dollars."
            } else {
                return "About \(MoneyFormat.currency(result.shortfall)) short of \(MoneyFormat.currency(inputs.targetAmount ?? 1_000))."
            }
        case .retirement:
            let comparison = RetirementPlanner.compare(
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
            return "Starting at \(Int(inputs.earlyStartAge ?? 23)) instead of \(Int(inputs.lateStartAge ?? 30)) could mean \(MoneyFormat.currency(comparison.differenceReal)) more, in today's dollars."
        }
    }

    /// A blank scenario of a kind, for "start from scratch" on Home.
    static func blank(kind: ScenarioKind) -> SavedScenario {
        let now = Date()
        let inputs: ScenarioInputs
        let title: String
        switch kind {
        case .oneTime:
            inputs = ScenarioInputs(kind: .oneTime, amount: 100, years: 20, assumptions: .default)
            title = "A $100 purchase"
        case .recurring:
            inputs = ScenarioInputs(kind: .recurring, monthlyAmount: 2.88, years: 20, assumptions: .default)
            title = "A $2.88 monthly payment"
        case .goal:
            inputs = ScenarioInputs(
                kind: .goal, years: 2, targetAmount: 1_000,
                currentSavings: 0, monthlyRedirect: 40, targetMonths: 24,
                assumptions: .default
            )
            title = "Save $1,000"
        case .retirement:
            inputs = ScenarioInputs(
                kind: .retirement, years: 42,
                earlyStartAge: 23, lateStartAge: 30, retirementAge: 65,
                monthlyContribution: 200, employerMatchRate: 0, employerMatchCapMonthly: 0,
                assumptions: .default
            )
            title = "Retirement at 23 vs 30"
        }
        return SavedScenario(
            id: UUID(), kind: kind, title: title,
            inputs: inputs, createdAt: now, updatedAt: now
        )
    }
}

// MARK: - Shared components

/// A label/value row with an optional footnote, used for results.
struct StatRow: View {
    let label: String
    let value: String
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.thenworthFootnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            if let footnote {
                Text(footnote)
                    .font(.thenworthFootnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small chip labeling one path of the fork.
struct PathLabelChip: View {
    enum Tone {
        case spend
        case grow
    }

    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(.thenworthFootnote)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                tone == .grow
                    ? Color.growthAccent.opacity(0.16)
                    : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .foregroundStyle(tone == .grow ? Color.forestDeep : Color.primary)
    }
}

/// Today's-dollars / future-dollars toggle. Defaults to today's dollars.
struct DollarsToggle: View {
    @Binding var basis: DollarBasis

    var body: some View {
        Picker("Dollars", selection: $basis) {
            ForEach(DollarBasis.allCases, id: \.self) { basis in
                Text(basis.label).tag(basis)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("dollars-toggle")
        .accessibilityLabel("Dollars shown as today's dollars or future dollars")
    }
}

/// The concrete-milestone line under the chart, e.g. "That is about a
/// used car." Hidden when the core has no translation for the amount.
struct MilestoneLine: View {
    let text: String?

    var body: some View {
        if let text {
            Label(text, systemImage: "sparkles")
                .font(.thenworthCaption)
                .foregroundStyle(Color.forestPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("milestone-line")
        }
    }
}

/// One editable assumption: a label, the current value, and a slider.
struct AssumptionRow: View {
    let label: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.thenworthBody)
                Spacer()
                Text(valueText)
                    .font(.thenworthHeadline)
                    .foregroundStyle(Color.forestDeep)
            }
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(valueText)
        }
        .padding(.vertical, 4)
    }
}

/// The note that appears wherever a projection is shown: hypothetical,
/// not guaranteed.
struct HypotheticalNote: View {
    var body: some View {
        Label(
            "Hypothetical, not guaranteed. These figures show what could happen under the assumptions you set; actual returns vary.",
            systemImage: "info.circle"
        )
        .font(.thenworthFootnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
import ThenworthCore

// MARK: - Scenario Detail
//
// One detail screen that adapts to the scenario kind: editable inputs,
// editable assumptions, live results, the Future Lens, and a plain-language
// "How this is calculated" section. State lives in `ScenarioViewModel`
// (Combine); this view is the form around it.
//
// NOTE: Written on the Linux VM; not compiled here. See App/README.md.

struct ScenarioDetailView: View {
    @EnvironmentObject private var store: ScenarioStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ScenarioViewModel
    @State private var saved = false

    private let isNew: Bool

    init(scenario: SavedScenario, isNew: Bool = false) {
        self.isNew = isNew
        _viewModel = StateObject(wrappedValue: ScenarioViewModel(scenario: scenario))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ThenworthSpace.large) {
                titleSection
                inputsSection
                assumptionsSection
                resultsSection
                FutureLensView(viewModel: viewModel)
                howCalculatedSection
            }
            .padding(ThenworthSpace.medium)
        }
        .background(Color.ivoryBackground)
        .navigationTitle(viewModel.kind.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .accessibilityIdentifier("save-scenario-button")
            }
        }
        .alert("Saved", isPresented: $saved) {
            Button("Done", role: .cancel) { dismiss() }
        } message: {
            Text("This future is saved in My Futures. You can reopen and change it any time.")
        }
    }

    private func save() {
        store.save(viewModel.currentScenario)
        saved = true
    }

    // MARK: Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text(viewModel.kind.subtitle)
                .font(.thenworthCaption)
                .foregroundStyle(.secondary)
            TextField("Title", text: $viewModel.title)
                .font(.thenworthTitle)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("scenario-title-field")
        }
    }

    // MARK: Inputs (per kind)

    @ViewBuilder
    private var inputsSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.medium) {
            Text("Your scenario")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            switch viewModel.kind {
            case .oneTime:
                moneyField(
                    label: "Amount today",
                    binding: viewModel.binding(for: \.amount, default: 100)
                )
                yearsStepper
            case .recurring:
                moneyField(
                    label: "Monthly amount",
                    binding: viewModel.binding(for: \.monthlyAmount, default: 2.88)
                )
                yearsStepper
            case .goal:
                moneyField(
                    label: "Target amount",
                    binding: viewModel.binding(for: \.targetAmount, default: 1_000)
                )
                moneyField(
                    label: "Saved so far",
                    binding: viewModel.binding(for: \.currentSavings, default: 0)
                )
                moneyField(
                    label: "Monthly amount you can redirect",
                    binding: viewModel.binding(for: \.monthlyRedirect, default: 40)
                )
                Stepper(
                    "Target date: \(targetDateText)",
                    value: viewModel.binding(for: \.targetMonths, default: 24),
                    in: 1...600,
                    step: 1
                )
                .accessibilityLabel("Months until target date")
            case .retirement:
                Stepper(
                    "Start saving at age \(Int(viewModel.binding(for: \.earlyStartAge, default: 23).wrappedValue))",
                    value: viewModel.binding(for: \.earlyStartAge, default: 23),
                    in: 16...70,
                    step: 1
                )
                Stepper(
                    "Compare with starting at age \(Int(viewModel.binding(for: \.lateStartAge, default: 30).wrappedValue))",
                    value: viewModel.binding(for: \.lateStartAge, default: 30),
                    in: 16...70,
                    step: 1
                )
                Stepper(
                    "Retire at age \(Int(viewModel.binding(for: \.retirementAge, default: 65).wrappedValue))",
                    value: viewModel.binding(for: \.retirementAge, default: 65),
                    in: 40...75,
                    step: 1
                )
                moneyField(
                    label: "Monthly contribution",
                    binding: viewModel.binding(for: \.monthlyContribution, default: 200)
                )
                AssumptionRow(
                    label: "Employer match",
                    valueText: MoneyFormat.percent(viewModel.binding(for: \.employerMatchRate, default: 0).wrappedValue),
                    value: viewModel.binding(for: \.employerMatchRate, default: 0),
                    range: 0...1, step: 0.01,
                    accessibilityLabel: "Employer match rate"
                )
                moneyField(
                    label: "Employer match cap (per month)",
                    binding: viewModel.binding(for: \.employerMatchCapMonthly, default: 0)
                )
            }
        }
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    private func moneyField(label: String, binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.thenworthBody)
            TextField(label, value: binding, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.thenworthHeadline)
        }
    }

    private var yearsStepper: some View {
        let years = viewModel.binding(for: \.years, default: 20)
        return Stepper(
            "Over \(MoneyFormat.yearsLabel(years.wrappedValue))",
            value: years,
            in: 1...50,
            step: 1
        )
        .accessibilityLabel("Years")
    }

    private var targetDateText: String {
        let months = viewModel.inputs.targetMonths ?? 24
        let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        return date.formatted(date: .abbreviated, time: .omitted)
            + " (\(MoneyFormat.monthsLabel(months)))"
    }

    // MARK: Assumptions

    private var assumptionsSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("Assumptions")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            Text("Change these to see how sensitive the result is. Nothing here is a prediction.")
                .font(.thenworthCaption)
                .foregroundStyle(.secondary)
            AssumptionRow(
                label: "Annual return",
                valueText: MoneyFormat.percent(viewModel.assumptionsBinding.wrappedValue.annualReturn),
                value: Binding(
                    get: { viewModel.assumptionsBinding.wrappedValue.annualReturn },
                    set: { viewModel.assumptionsBinding.wrappedValue.annualReturn = $0 }
                ),
                range: 0...0.15, step: 0.005,
                accessibilityLabel: "Assumed annual return"
            )
            AssumptionRow(
                label: "Annual inflation",
                valueText: MoneyFormat.percent(viewModel.assumptionsBinding.wrappedValue.annualInflation),
                value: Binding(
                    get: { viewModel.assumptionsBinding.wrappedValue.annualInflation },
                    set: { viewModel.assumptionsBinding.wrappedValue.annualInflation = $0 }
                ),
                range: 0...0.08, step: 0.005,
                accessibilityLabel: "Assumed annual inflation"
            )
            Picker("Compounding", selection: Binding(
                get: { viewModel.assumptionsBinding.wrappedValue.compounding },
                set: { viewModel.assumptionsBinding.wrappedValue.compounding = $0 }
            )) {
                ForEach(compoundingChoices, id: \.self) { frequency in
                    Text(compoundingLabel(frequency)).tag(frequency)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Compounding frequency")
            HypotheticalNote()
        }
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    private var compoundingChoices: [CompoundingFrequency] {
        [.annually, .quarterly, .monthly, .daily]
    }

    private func compoundingLabel(_ frequency: CompoundingFrequency) -> String {
        switch frequency {
        case .annually: return "Yearly"
        case .quarterly: return "Quarterly"
        case .monthly: return "Monthly"
        case .daily: return "Daily"
        }
    }

    // MARK: Results (live, from the core)

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("What the numbers say")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            switch viewModel.kind {
            case .oneTime:
                let amount = viewModel.inputs.amount ?? 100
                let nominal = FinancialEngine.futureValue(
                    principal: amount,
                    annualRate: viewModel.inputs.assumptions.annualReturn,
                    years: viewModel.inputs.years ?? 20,
                    compounding: viewModel.inputs.assumptions.compounding
                )
                let real = FinancialEngine.realValue(
                    nominal: nominal,
                    annualInflation: viewModel.inputs.assumptions.annualInflation,
                    years: viewModel.inputs.years ?? 20
                )
                StatRow(label: "If it grows instead", value: MoneyFormat.currency(real), footnote: "In today's dollars · \(MoneyFormat.currency(nominal)) in future dollars")
                StatRow(label: "Of that, growth", value: MoneyFormat.currency(max(0, real - amount)), footnote: "The rest is the \(MoneyFormat.currency(amount)) you started with")
            case .recurring:
                let monthly = viewModel.inputs.monthlyAmount ?? 2.88
                let years = viewModel.inputs.years ?? 20
                let paid = FinancialEngine.totalPaid(monthlyAmount: monthly, years: years)
                StatRow(label: "Total paid over \(MoneyFormat.yearsLabel(years))", value: MoneyFormat.currency(paid), footnote: "Money contributed, before any growth")
                StatRow(label: "If redirected instead", value: MoneyFormat.currency(viewModel.lens.finalSecond), footnote: "In today's dollars · of that, \(MoneyFormat.currency(max(0, viewModel.lens.finalSecond - FinancialEngine.realValue(nominal: paid, annualInflation: viewModel.inputs.assumptions.annualInflation, years: years)))) is growth")
            case .goal:
                if let result = viewModel.goalResult {
                    StatRow(
                        label: result.onTrack ? "On track" : "Shortfall",
                        value: result.onTrack
                            ? MoneyFormat.currency(result.projectedRealAtTargetDate)
                            : MoneyFormat.currency(result.shortfall),
                        footnote: result.onTrack
                            ? "Projected by the target date, in today's dollars"
                            : "Still needed to reach \(MoneyFormat.currency(result.target))"
                    )
                    StatRow(
                        label: "Months to goal at this pace",
                        value: result.monthsToGoal.map { "\($0) months" } ?? "More than 100 years",
                        footnote: "Target date is \(MoneyFormat.monthsLabel(result.targetMonths)) away"
                    )
                }
            case .retirement:
                if let comparison = viewModel.retirementComparison {
                    StatRow(label: "Starting at \(comparison.early.startAge)", value: MoneyFormat.currency(comparison.early.finalReal), footnote: "In today's dollars · \(MoneyFormat.currency(comparison.early.finalNominal)) in future dollars")
                    StatRow(label: "Starting at \(comparison.late.startAge)", value: MoneyFormat.currency(comparison.late.finalReal), footnote: "In today's dollars · \(MoneyFormat.currency(comparison.late.finalNominal)) in future dollars")
                    StatRow(label: "Difference", value: MoneyFormat.currency(comparison.differenceReal), footnote: "What the earlier start is worth, in today's dollars")
                }
            }
        }
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    // MARK: How this is calculated

    private var howCalculatedSection: some View {
        DisclosureGroup("How this is calculated") {
            VStack(alignment: .leading, spacing: ThenworthSpace.small) {
                ForEach(howCalculatedLines, id: \.self) { line in
                    Text("•  \(line)")
                        .font(.thenworthCaption)
                        .foregroundStyle(.secondary)
                }
                Text("Money you contribute and growth are shown separately wherever they can be. Nominal means future dollars; real means today's dollars, adjusted for inflation at the rate you set.")
                    .font(.thenworthCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, ThenworthSpace.small)
        }
        .font(.thenworthHeadline)
        .foregroundStyle(Color.forestDeep)
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    private var howCalculatedLines: [String] {
        switch viewModel.kind {
        case .oneTime:
            return [
                "Future value: the amount grows at the annual return you set, compounded \(compoundingLabel(viewModel.inputs.assumptions.compounding).lowercased()).",
                "Today's dollars: the future value is divided by (1 + inflation) raised to the number of years.",
                "The \"spend now\" path stays flat at the purchase amount: you got the thing, worth what you paid.",
            ]
        case .recurring:
            return [
                "Total paid: the monthly amount times 12 months times the number of years.",
                "Redirected value: each monthly payment grows at the annual return from the month it is paid, compounded \(compoundingLabel(viewModel.inputs.assumptions.compounding).lowercased()).",
                "Today's dollars: both paths are adjusted for inflation at the rate you set.",
            ]
        case .goal:
            return [
                "Projected value: your current savings grow at the annual return, plus each monthly redirect growing from the month it is paid.",
                "On track means the projected value at the target date reaches the target. Shortfall is target minus projected.",
                "Months to goal: how long the same monthly amount would need to reach the target.",
            ]
        case .retirement:
            return [
                "Each side: monthly contributions plus the employer match (capped per month) grow at the annual return from the month they are paid.",
                "The early side starts contributing at the earlier age; the late side starts at the later age. Both stop at the retirement age.",
                "Difference: the early side's final value minus the late side's, shown in today's dollars and future dollars.",
            ]
        }
    }
}

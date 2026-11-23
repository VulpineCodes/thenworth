import Foundation

/// Prebuilt synthetic demo scenarios shown on first launch. All figures are
/// made-up examples, not the user's data.
public enum SampleScenarios {

    public static let all: [SavedScenario] = [
        SavedScenario(
            kind: .oneTime,
            title: "The $100 purchase",
            inputs: ScenarioInputs(
                kind: .oneTime,
                amount: 100,
                years: 20,
                assumptions: .default
            )
        ),
        SavedScenario(
            kind: .recurring,
            title: "$2.88 a month for iCloud",
            inputs: ScenarioInputs(
                kind: .recurring,
                monthlyAmount: 2.88,
                years: 20,
                assumptions: .default
            )
        ),
        SavedScenario(
            kind: .goal,
            title: "Save for a car",
            inputs: ScenarioInputs(
                kind: .goal,
                targetAmount: 12_000,
                currentSavings: 1_500,
                monthlyRedirect: 200,
                targetMonths: 24,
                assumptions: .default
            )
        ),
        SavedScenario(
            kind: .retirement,
            title: "Start retirement saving at 23 vs 30",
            inputs: ScenarioInputs(
                kind: .retirement,
                earlyStartAge: 23,
                lateStartAge: 30,
                retirementAge: 65,
                monthlyContribution: 300,
                employerMatchRate: 0.05,
                employerMatchCapMonthly: 150,
                assumptions: .default
            )
        ),
    ]
}

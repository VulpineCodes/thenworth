import AppIntents
import ThenworthCore

// MARK: - Thenworth App Intents (App Intents + Shortcuts)
//
// One minimal intent: ask what an amount could be worth in N years, and
// get the answer in today's dollars. It is exposed to Shortcuts and Siri
// through the AppShortcut below, so Franklin can ask from anywhere
// without opening the app.
//
// This file belongs to the app target (no separate target needed);
// App Intents are not available on the Linux VM, so it is written but
// NOT compiled here. See App/README.md.
//
// Deliberately minimal: one intent, one shortcut, default assumptions
// (7% return, 3% inflation, monthly compounding). No intent for saving
// scenarios or editing data; that stays in the app.

struct WorthInYearsIntent: AppIntent {
    static var title: LocalizedStringResource = "What is it worth in N years?"
    static var description = IntentDescription(
        "See what an amount today could be worth in a number of years, in today's dollars."
    )

    @Parameter(title: "Amount", description: "The amount today, in dollars.")
    var amount: Double

    @Parameter(title: "Years", description: "How many years ahead to look.")
    var years: Int

    static var parameterSummary: some ParameterSummary {
        Summary("What is $\(\.$amount) worth in \(\.$years) years?")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let nominal = FinancialEngine.futureValue(
            principal: amount,
            annualRate: Assumptions.default.annualReturn,
            years: Double(years),
            compounding: Assumptions.default.compounding
        )
        let real = FinancialEngine.realValue(
            nominal: nominal,
            annualInflation: Assumptions.default.annualInflation,
            years: Double(years)
        )
        // Returns the value in today's dollars. Shortcuts displays it;
        // the figure is hypothetical, under the default assumptions.
        return .result(value: real)
    }
}

struct ThenworthShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WorthInYearsIntent(),
            phrases: [
                "What is it worth in \(.applicationName)",
                "Check my future value with \(.applicationName)",
            ],
            shortTitle: "Future value",
            systemImageName: "chart.line.uptrend.xyaxis"
        )
    }
}

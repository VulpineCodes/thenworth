import XCTest
import ThenworthCore

final class ModelsTests: XCTestCase {

    // MARK: - Codable round trips

    func testAssumptionsRoundTrip() throws {
        let assumptions = Assumptions.default
        XCTAssertEqual(try TestFixtures.roundTrip(assumptions), assumptions)
        XCTAssertEqual(try TestFixtures.roundTrip(Assumptions.cash), Assumptions.cash)
    }

    func testScenarioInputsRoundTrip() throws {
        let inputs = ScenarioInputs(
            kind: .retirement,
            earlyStartAge: 23,
            lateStartAge: 30,
            retirementAge: 65,
            monthlyContribution: 300,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            assumptions: .default
        )
        XCTAssertEqual(try TestFixtures.roundTrip(inputs), inputs)
    }

    func testSavedScenarioRoundTrip() throws {
        let scenario = SavedScenario(
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
        )
        let decoded = try TestFixtures.roundTrip(scenario)
        XCTAssertEqual(decoded, scenario)
        XCTAssertEqual(decoded.kind, .goal)
        XCTAssertEqual(decoded.inputs.targetAmount, 12_000)
    }

    func testSavedScenarioPreservesNilFields() throws {
        let inputs = ScenarioInputs(kind: .oneTime, amount: 100, years: 20)
        let decoded = try TestFixtures.roundTrip(inputs)
        XCTAssertNil(decoded.monthlyAmount)
        XCTAssertNil(decoded.targetAmount)
        XCTAssertNil(decoded.earlyStartAge)
        XCTAssertEqual(decoded.amount, 100)
        XCTAssertEqual(decoded.years, 20)
    }

    func testScenarioInputsNegativeInputsClamp() {
        let inputs = ScenarioInputs(kind: .oneTime, amount: -100, years: -5)
        XCTAssertEqual(inputs.amount, 0)
        XCTAssertEqual(inputs.years, 0)
    }

    func testAssumptionsNegativeInputsClamp() {
        let assumptions = Assumptions(annualReturn: -0.05, annualInflation: -0.02, compounding: .monthly)
        XCTAssertEqual(assumptions.annualReturn, 0)
        XCTAssertEqual(assumptions.annualInflation, 0)
    }

    // MARK: - Scenario kinds

    func testAllScenarioKindsExist() {
        XCTAssertEqual(ScenarioKind.allCases.count, 4)
        XCTAssertTrue(ScenarioKind.allCases.contains(.oneTime))
        XCTAssertTrue(ScenarioKind.allCases.contains(.recurring))
        XCTAssertTrue(ScenarioKind.allCases.contains(.goal))
        XCTAssertTrue(ScenarioKind.allCases.contains(.retirement))
    }

    // MARK: - Sample scenarios

    func testSampleScenariosCountAndKinds() {
        XCTAssertEqual(SampleScenarios.all.count, 4)
        XCTAssertEqual(SampleScenarios.all.map(\.kind), [.oneTime, .recurring, .goal, .retirement])
    }

    func testSampleOneTimePurchase() {
        let scenario = SampleScenarios.all[0]
        XCTAssertEqual(scenario.title, "The $100 purchase")
        XCTAssertEqual(scenario.inputs.amount, 100)
        XCTAssertEqual(scenario.inputs.years, 20)
        XCTAssertEqual(scenario.inputs.assumptions, .default)
    }

    func testSampleRecurringSubscription() {
        let scenario = SampleScenarios.all[1]
        XCTAssertEqual(scenario.inputs.monthlyAmount, 2.88)
        XCTAssertEqual(scenario.inputs.years, 20)
        // Redirecting it at 7% for 20 years accumulates $1,500.27
        // (independent Python value, see FinancialEngineTests).
        assertDollarsEqual(
            FinancialEngine.redirectedValue(
                monthlyAmount: scenario.inputs.monthlyAmount ?? 0,
                annualRate: scenario.inputs.assumptions.annualReturn,
                years: scenario.inputs.years ?? 0,
                compounding: scenario.inputs.assumptions.compounding
            ),
            1_500.27
        )
    }

    func testSampleCarGoal() {
        let scenario = SampleScenarios.all[2]
        XCTAssertEqual(scenario.inputs.targetAmount, 12_000)
        XCTAssertEqual(scenario.inputs.currentSavings, 1_500)
        XCTAssertEqual(scenario.inputs.monthlyRedirect, 200)
        XCTAssertEqual(scenario.inputs.targetMonths, 24)
        let result = GoalPlanner.plan(
            target: scenario.inputs.targetAmount ?? 0,
            currentSavings: scenario.inputs.currentSavings ?? 0,
            monthlyRedirect: scenario.inputs.monthlyRedirect ?? 0,
            annualRate: scenario.inputs.assumptions.annualReturn,
            annualInflation: scenario.inputs.assumptions.annualInflation,
            targetMonths: scenario.inputs.targetMonths ?? 0,
            compounding: scenario.inputs.assumptions.compounding
        )
        XCTAssertFalse(result.onTrack)
        XCTAssertEqual(result.monthsToGoal, 45)
    }

    func testSampleRetirementComparison() {
        let scenario = SampleScenarios.all[3]
        XCTAssertEqual(scenario.inputs.earlyStartAge, 23)
        XCTAssertEqual(scenario.inputs.lateStartAge, 30)
        XCTAssertEqual(scenario.inputs.retirementAge, 65)
        XCTAssertEqual(scenario.inputs.monthlyContribution, 300)
        XCTAssertEqual(scenario.inputs.employerMatchRate, 0.05)
        XCTAssertEqual(scenario.inputs.employerMatchCapMonthly, 150)
        let comparison = RetirementPlanner.compare(
            earlyStartAge: scenario.inputs.earlyStartAge ?? 0,
            lateStartAge: scenario.inputs.lateStartAge ?? 0,
            retirementAge: scenario.inputs.retirementAge ?? 0,
            monthlyContribution: scenario.inputs.monthlyContribution ?? 0,
            annualReturn: scenario.inputs.assumptions.annualReturn,
            annualInflation: scenario.inputs.assumptions.annualInflation,
            employerMatchRate: scenario.inputs.employerMatchRate ?? 0,
            employerMatchCapMonthly: scenario.inputs.employerMatchCapMonthly ?? 0,
            compounding: scenario.inputs.assumptions.compounding
        )
        // Independent Python values, see RetirementPlannerTests.
        assertDollarsEqual(comparison.early.finalNominal, 958_767.79)
        assertDollarsEqual(comparison.differenceNominal, 391_435.59)
    }

    func testSampleScenariosHaveUniqueIds() {
        let ids = SampleScenarios.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}

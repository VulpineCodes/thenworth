import XCTest
import ThenworthCore

/// Expected values below were computed independently in Python.
/// Car goal: 1500*(1+0.07/12)**24 = 1724.71; annuity 200/mo for 24 months
/// = 5136.21; projected 6860.92; real 6860.92/(1.03**2) = 6467.07.
/// Months to goal found by the same Python loop over whole months.
final class GoalPlannerTests: XCTestCase {

    private func carGoal(target: Double = 12_000) -> GoalResult {
        GoalPlanner.plan(
            target: target,
            currentSavings: 1_500,
            monthlyRedirect: 200,
            annualRate: 0.07,
            annualInflation: 0.03,
            targetMonths: 24,
            compounding: .monthly
        )
    }

    func testCarGoalShortfallCase() {
        // A $12,000 car with $1,500 saved and $200/month for 24 months
        // is not reachable on the target date.
        let result = carGoal()
        assertDollarsEqual(result.projectedAtTargetDate, 6_860.92)
        assertDollarsEqual(result.projectedRealAtTargetDate, 6_467.07)
        assertDollarsEqual(result.shortfall, 5_139.08)
        XCTAssertFalse(result.onTrack)
        XCTAssertEqual(result.targetMonths, 24)
    }

    func testCarGoalMonthsToGoal() {
        // Python month-by-month loop: first month reaching $12,000 is
        // month 45, at $12,206.56.
        XCTAssertEqual(carGoal().monthsToGoal, 45)
    }

    func testGoalOnTrackCase() {
        // Same savings plan against a $6,000 target: projected $6,860.92
        // clears it, so there is no shortfall.
        let result = carGoal(target: 6_000)
        assertDollarsEqual(result.projectedAtTargetDate, 6_860.92)
        XCTAssertEqual(result.shortfall, 0)
        XCTAssertTrue(result.onTrack)
        // Python: first month reaching $6,000 is month 21, at $6,149.17.
        XCTAssertEqual(result.monthsToGoal, 21)
    }

    func testGoalZeroRate() {
        // No return: 1500 + 200*24 = 6300 after 24 months.
        let result = GoalPlanner.plan(
            target: 12_000,
            currentSavings: 1_500,
            monthlyRedirect: 200,
            annualRate: 0,
            annualInflation: 0.03,
            targetMonths: 24,
            compounding: .monthly
        )
        assertDollarsEqual(result.projectedAtTargetDate, 6_300)
        assertDollarsEqual(result.shortfall, 5_700)
        XCTAssertFalse(result.onTrack)
        // ceil((12000-1500)/200) = 53 months: 52 months gives 11900.
        XCTAssertEqual(result.monthsToGoal, 53)
    }

    func testGoalAlreadySaved() {
        let result = GoalPlanner.plan(
            target: 5_000,
            currentSavings: 5_000,
            monthlyRedirect: 0,
            annualRate: 0.07,
            annualInflation: 0.03,
            targetMonths: 12,
            compounding: .monthly
        )
        XCTAssertTrue(result.onTrack)
        XCTAssertEqual(result.shortfall, 0)
        XCTAssertEqual(result.monthsToGoal, 0)
    }

    func testGoalUnreachableWithNoSavingsAndNoReturn() {
        let result = GoalPlanner.plan(
            target: 12_000,
            currentSavings: 0,
            monthlyRedirect: 0,
            annualRate: 0,
            annualInflation: 0.03,
            targetMonths: 24,
            compounding: .monthly
        )
        XCTAssertEqual(result.projectedAtTargetDate, 0)
        assertDollarsEqual(result.shortfall, 12_000)
        XCTAssertFalse(result.onTrack)
        XCTAssertNil(result.monthsToGoal)
    }

    func testGoalReachableFromGrowthAlone() {
        // $11,000 saved, no monthly redirect, 7% return: growth alone
        // reaches $12,000, so monthsToGoal is a real number, not nil.
        let result = GoalPlanner.plan(
            target: 12_000,
            currentSavings: 11_000,
            monthlyRedirect: 0,
            annualRate: 0.07,
            annualInflation: 0.03,
            targetMonths: 24,
            compounding: .monthly
        )
        XCTAssertNotNil(result.monthsToGoal)
        XCTAssertLessThan(result.monthsToGoal ?? .max, 24)
    }

    func testGoalNegativeInputsClamp() {
        let result = GoalPlanner.plan(
            target: -5_000,
            currentSavings: -100,
            monthlyRedirect: -50,
            annualRate: -0.07,
            annualInflation: -0.03,
            targetMonths: -6,
            compounding: .monthly
        )
        XCTAssertEqual(result.target, 0)
        XCTAssertEqual(result.currentSavings, 0)
        XCTAssertEqual(result.monthlyRedirect, 0)
        XCTAssertEqual(result.targetMonths, 0)
        XCTAssertTrue(result.onTrack)
        XCTAssertEqual(result.monthsToGoal, 0)
    }

    func testGoalResultEchoesInputs() {
        let result = carGoal()
        XCTAssertEqual(result.target, 12_000)
        XCTAssertEqual(result.currentSavings, 1_500)
        XCTAssertEqual(result.monthlyRedirect, 200)
    }
}

import XCTest
import ThenworthCore

/// Expected values below were computed independently in Python.
/// $300/month plus a 5% match ($15/month, under the $150 cap) is $315/month.
/// Early (23 to 65, 42 years): 315*(((1+0.07/12)**504-1)/(0.07/12))
/// = 958767.79 nominal; contributions 151200; match 7560; growth 800007.79;
/// real 958767.79/(1.03**42) = 277044.80.
/// Late (30 to 65, 35 years): 567332.20 nominal; contributions 126000;
/// match 6300; growth 435032.20; real 201620.44.
/// Differences: nominal 391435.59, real 75424.36.
final class RetirementPlannerTests: XCTestCase {

    private func standardComparison() -> RetirementComparison {
        RetirementPlanner.compare(
            earlyStartAge: 23,
            lateStartAge: 30,
            retirementAge: 65,
            monthlyContribution: 300,
            annualReturn: 0.07,
            annualInflation: 0.03,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
    }

    func testEarlySideBreakdown() {
        let early = standardComparison().early
        XCTAssertEqual(early.startAge, 23)
        assertDollarsEqual(early.contributions, 151_200)
        assertDollarsEqual(early.employerMatch, 7_560)
        assertDollarsEqual(early.growth, 800_007.79)
        assertDollarsEqual(early.finalNominal, 958_767.79)
        assertDollarsEqual(early.finalReal, 277_044.80)
        // The parts add up to the whole.
        assertDollarsEqual(
            early.contributions + early.employerMatch + early.growth,
            early.finalNominal
        )
    }

    func testLateSideBreakdown() {
        let late = standardComparison().late
        XCTAssertEqual(late.startAge, 30)
        assertDollarsEqual(late.contributions, 126_000)
        assertDollarsEqual(late.employerMatch, 6_300)
        assertDollarsEqual(late.growth, 435_032.20)
        assertDollarsEqual(late.finalNominal, 567_332.20)
        assertDollarsEqual(late.finalReal, 201_620.44)
        assertDollarsEqual(
            late.contributions + late.employerMatch + late.growth,
            late.finalNominal
        )
    }

    func testEarlyVsLateDifferenceIsPositive() {
        let comparison = standardComparison()
        XCTAssertGreaterThan(comparison.differenceNominal, 0)
        XCTAssertGreaterThan(comparison.differenceReal, 0)
        assertDollarsEqual(comparison.differenceNominal, 391_435.59)
        assertDollarsEqual(comparison.differenceReal, 75_424.36)
    }

    func testMatchIsCountedSeparatelyFromGrowth() {
        // The match is money in, not growth: growth must exclude it.
        let comparison = standardComparison()
        XCTAssertEqual(comparison.early.employerMatch, 7_560)
        XCTAssertEqual(comparison.late.employerMatch, 6_300)
        // If the match were wrongly counted as growth, growth would be
        // higher by exactly the match amount.
        XCTAssertLessThan(comparison.early.growth, comparison.early.finalNominal - comparison.early.contributions)
    }

    func testMatchCapBinds() {
        // $4,000/month at a 5% match would be $200/month, but the $150
        // cap binds, so the match is $150/month: 150 * 420 months = 63000
        // for the early side (age 30 to 65, 35 years).
        let comparison = RetirementPlanner.compare(
            earlyStartAge: 30,
            lateStartAge: 40,
            retirementAge: 65,
            monthlyContribution: 4_000,
            annualReturn: 0.07,
            annualInflation: 0.03,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
        assertDollarsEqual(comparison.early.employerMatch, 63_000)
        // Late side: 25 years = 300 months at $150 = 45000.
        assertDollarsEqual(comparison.late.employerMatch, 45_000)
    }

    func testNoMatchWhenRateIsZero() {
        let comparison = RetirementPlanner.compare(
            earlyStartAge: 23,
            lateStartAge: 30,
            retirementAge: 65,
            monthlyContribution: 300,
            annualReturn: 0.07,
            annualInflation: 0.03,
            employerMatchRate: 0,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
        XCTAssertEqual(comparison.early.employerMatch, 0)
        XCTAssertEqual(comparison.late.employerMatch, 0)
    }

    func testSameStartAgeMeansNoDifference() {
        let comparison = RetirementPlanner.compare(
            earlyStartAge: 30,
            lateStartAge: 30,
            retirementAge: 65,
            monthlyContribution: 300,
            annualReturn: 0.07,
            annualInflation: 0.03,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
        XCTAssertEqual(comparison.early, comparison.late)
        XCTAssertEqual(comparison.differenceNominal, 0)
        XCTAssertEqual(comparison.differenceReal, 0)
    }

    func testStartAgeAtOrAfterRetirementIsZero() {
        let comparison = RetirementPlanner.compare(
            earlyStartAge: 65,
            lateStartAge: 70,
            retirementAge: 65,
            monthlyContribution: 300,
            annualReturn: 0.07,
            annualInflation: 0.03,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
        XCTAssertEqual(comparison.early.finalNominal, 0)
        XCTAssertEqual(comparison.late.finalNominal, 0)
        XCTAssertEqual(comparison.differenceNominal, 0)
    }

    func testCashRetirementHasNoGrowth() {
        // 0% return: the final value is exactly contributions plus match.
        let comparison = RetirementPlanner.compare(
            earlyStartAge: 23,
            lateStartAge: 30,
            retirementAge: 65,
            monthlyContribution: 300,
            annualReturn: 0,
            annualInflation: 0.03,
            employerMatchRate: 0.05,
            employerMatchCapMonthly: 150,
            compounding: .monthly
        )
        assertDollarsEqual(comparison.early.finalNominal, 151_200 + 7_560)
        XCTAssertEqual(comparison.early.growth, 0)
    }
}
